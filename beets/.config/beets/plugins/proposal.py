"""Adds `beet propose`. It proposes how soulseek_import would file album folders.

`beet propose -o FILE [--id RELEASE_ID] FOLDER...` matches the audio files directly in each given
folder against the enabled metadata sources. For each folder it prints the best match, the library
path of each file, the missing tracks, and the proposed classification and genres, and it appends
one record to FILE. Neither the library nor any file changes.

Each record is one line of RECORD_FIELDS separated by U+001F (the ASCII unit separator). Unlike a
tab, said separator keeps empty fields apart when bash splits the line with `read`.

A folder fails if it has no audio files, has no candidate, or has a best candidate below the
medium recommendation threshold (sans when --id names the release). It also fails if a file
matches no track of the release, if the release is already in the library, or if `beet import`
would skip the album as a duplicate of a library album or of an earlier folder of the same
invocation.
"""

import collections
import os
import tempfile

from beets import config
from beets.autotag import Source, tag_album
from beets.dbcore.query import MatchQuery
from beets.library import Album, Library
from beets.plugins import BeetsPlugin
from beets.ui import Subcommand
from beets.util import displayable_path
from beetsplug.candidates import audio_items

SEPARATOR = "\x1f"
RECORD_FIELDS = [
    "folder", "status", "reason", "release_id", "tracks", "missing", "missing_note", "category",
    "label_type", "destination", "genres",
]
# beets formats a multi-value field such as genres by joining its values with this delimiter
GENRE_DELIMITER = "; "
# The flexible field that the archive path rules in config.yaml match on
ARCHIVE_FIELD = "archive"
# The number of runner-up candidates printed after the best match
ALTERNATIVES = 2


def field(value):
    """Returns the given value as text that fits in one field of a record."""
    text = "" if value is None else str(value)
    return " ".join(text.replace(SEPARATOR, " ").splitlines())


def missing_note(info, extra_tracks):
    """Describes the tracks of the release info that no file matches, in the format of the
    missing_note field of the library's albums: "missing N of M: #<disc>-<track> <title>; ...". A disc of which no
    track is present is described as "disc N (K tracks)"."""
    if not extra_tracks:
        return ""
    # The number of tracks on each disc; a track without a disc number is on disc 1
    media = collections.Counter(track.medium or 1 for track in info.tracks)
    by_disc = collections.defaultdict(list)
    for track in extra_tracks:
        by_disc[track.medium or 1].append(track)
    parts = []
    for disc, tracks in sorted(by_disc.items()):
        if len(tracks) == media[disc] and len(media) > 1:
            parts.append(f"disc {disc} ({len(tracks)} tracks)")
            continue
        # The disc prefix appears only on releases of more than one disc
        prefix = f"{disc}-" if len(media) > 1 else ""
        parts.extend(f"#{prefix}{track.medium_index or track.index} {track.title}" for track in tracks)
    return f"missing {len(extra_tracks)} of {len(info.tracks)}: " + "; ".join(parts)


def most_common(lib, value_field, match_field, value):
    """Returns the most common value of the given value_field among the library albums whose
    match_field equals the given value, and the number of albums it was counted from."""
    if not value:
        return "", 0
    values = collections.Counter(
        album.get(value_field) for album in lib.albums(MatchQuery(match_field, value))
        if album.get(value_field)
    )
    if not values:
        return "", 0
    return values.most_common(1)[0][0], values.total()


def proposed_genres(lib, items, artist):
    """Returns the genres of the given items' tags, most frequent first, and where they came from.
    If the tags contain no genre, returns the genres of the library albums by the given artist
    instead. The result is only a proposal; soulseek_import --apply sets the genres the user
    confirms."""
    counts = collections.Counter(genre for item in items for genre in item.get("genres") or [])
    source = "the files' tags"
    if not counts:
        albums = lib.albums(MatchQuery("albumartist", artist))
        counts = collections.Counter(genre for album in albums for genre in album.get("genres") or [])
        source = f"albums by {artist}"
    return [genre for genre, _ in counts.most_common()], source


def destinations(lib, match, scratch_dir):
    """Returns the sorted (file name, library path) pairs of the matched files, with the match
    applied and the album marked as archived.

    `Item.destination` requires an item stored in a library, so we store the items in a scratch
    library in the given scratch_dir. Said library shares the real library's folder and the
    configured path rules, so it yields the paths that `beet import` would. The items are read
    from the files and never written back."""
    # A new database receives every schema migration, and beets would otherwise back the empty
    # database up prior to each one
    backups = config["create_backup_before_migrations"].get(bool)
    config["create_backup_before_migrations"].set(False)
    scratch = Library(os.path.join(scratch_dir, "scratch.db"), lib.directory, set_music_dir=False)
    config["create_backup_before_migrations"].set(backups)
    match.apply_metadata()
    for item in match.items:
        item[ARCHIVE_FIELD] = 1
    scratch.add_album(match.items)
    return sorted(
        (os.path.basename(displayable_path(item.path)),
         displayable_path(item.destination(relative_to_libdir=True)))
        for item in match.items
    )


def failure(lib, match, forced):
    """Returns why the folder cannot be imported with the given match, or an empty string. The
    given flag forced is true if --id named the release, which waives the similarity threshold."""
    # beets' distance is 0 for a perfect match and 1 for none; similarity is 1 - distance
    threshold = config["match"]["medium_rec_thresh"].as_number()
    if not forced and match.distance > threshold:
        return f"best match {(1 - float(match.distance)) * 100:.1f}% is below {(1 - threshold) * 100:.0f}%"
    if match.extra_items:
        return f"{len(match.extra_items)} files match no track of the release"
    # Discogs releases also store their release ID in mb_albumid
    existing = lib.albums(MatchQuery("mb_albumid", match.info.album_id)).get()
    if existing is not None:
        return f"the release is already in the library at {displayable_path(existing.item_dir())}"
    duplicate = lib.albums(release_album(lib, match.info).duplicates_query(duplicate_keys())).get()
    if duplicate is not None:
        return f"beets would skip it as a duplicate of {displayable_path(duplicate.item_dir())}"
    return ""


def duplicate_keys():
    """Returns the album fields on which `beet import` finds duplicates (albumartist and album by
    default)."""
    return config["import"]["duplicate_keys"]["album"].as_str_seq()


def release_album(lib, info):
    """Returns an unsaved album of the release info, built as ImportTask.find_duplicates builds
    one."""
    data = info.copy()
    data["albumartist"] = data["artist"]
    return Album(lib, **data)


class Proposal:
    """The proposal for one folder: its record and the lines that describe it."""

    def __init__(self, folder):
        self.record = dict.fromkeys(RECORD_FIELDS, "") | {"folder": folder, "status": "fail"}
        self.lines = [folder]
        # The duplicate_keys values of the matched release; two folders of one invocation must
        # not share them
        self.duplicate_values = None

    def fail(self, reason):
        """Marks the proposal as failed for the given reason and returns it."""
        self.record["status"] = "fail"
        self.record["reason"] = reason
        self.lines.append(f"  result    FAIL: {reason}")
        return self

    def describe(self, lib, proposal, forced, scratch_dir):
        """Fills the record and lines from the best candidate of the given beets proposal, then
        passes or fails the proposal and returns it."""
        best = proposal.candidates[0]
        info = best.info
        # destinations applies the match to the items, so the tags' genres are read first
        genres, genre_source = proposed_genres(lib, best.items, info.artist)
        files = destinations(lib, best, scratch_dir)
        note = missing_note(info, best.extra_tracks)
        category, category_count = most_common(lib, "category", "albumartist", info.artist)
        label_type, label_count = most_common(lib, "label_type", "label", info.label)
        self.record |= {
            "release_id": info.album_id, "tracks": len(files), "missing": len(best.extra_tracks),
            "missing_note": note, "category": category, "label_type": label_type,
            "destination": os.path.dirname(files[0][1]), "genres": GENRE_DELIMITER.join(genres),
        }
        self.lines.append(f"  match     {candidate_text(best)}")
        self.lines.append(f"  folder    {self.record['destination']}")
        self.lines.extend(f"  file      {name} -> {os.path.basename(path)}" for name, path in files)
        self.lines.append(f"  missing   {note or 'none'}")
        self.lines.append(f"  category  {category or '?'} (from {category_count} albums by {info.artist})")
        self.lines.append(f"  label     {label_type or '?'} (from {label_count} albums on {info.label or 'no label'})")
        self.lines.append(f"  genres    {', '.join(genres) or '?'} (from {genre_source})")
        self.lines.extend(f"  other     {candidate_text(m)}" for m in proposal.candidates[1:1 + ALTERNATIVES])
        album = release_album(lib, info)
        self.duplicate_values = tuple(str(album.get(key)) for key in duplicate_keys())
        reason = failure(lib, best, forced)
        if reason:
            return self.fail(reason)
        self.record["status"] = "ok"
        return self


def candidate_text(match):
    """Describes the given candidate match in one line: similarity, release, and source ID."""
    info = match.info
    year = f" ({info.year})" if info.year else ""
    return (f"{(1 - float(match.distance)) * 100:.1f}%  {info.artist} - {info.album}{year}, "
            f"{len(info.tracks)} tracks, {info.data_source} {info.album_id}")


def propose(lib, folder, release_id):
    """Returns the Proposal for the given folder, matched only against the given release_id if
    it is not None."""
    result = Proposal(folder)
    items = audio_items(folder)
    if not items:
        return result.fail("no audio files")
    proposal = tag_album(Source.from_items(items), search_ids=[release_id] if release_id else [])
    if not proposal.candidates:
        return result.fail("no candidates")
    with tempfile.TemporaryDirectory() as scratch_dir:
        return result.describe(lib, proposal, bool(release_id), scratch_dir)


class ProposalPlugin(BeetsPlugin):
    def commands(self):
        command = Subcommand("propose", help="propose how soulseek_import would file album folders")
        command.parser.add_option("-o", "--output", help="file to append one record per folder to")
        command.parser.add_option("-i", "--id", help="match only against this release ID")
        command.func = self.run
        return [command]

    def run(self, lib, opts, args):
        """Proposes each given folder in order, then prints its lines and appends its record."""
        # The duplicate_keys values of each folder that passed, mapped to said folder. beet import
        # skips the second of two albums with equal values, so the second fails here.
        passed = {}
        with open(opts.output, "a", encoding="utf-8") as handle:
            for folder in args:
                try:
                    result = propose(lib, folder, opts.id)
                except Exception as error:  # A bad file must not stop the other folders
                    result = Proposal(folder).fail(f"error: {error}")
                earlier = passed.get(result.duplicate_values)
                if result.record["status"] == "ok" and earlier is not None:
                    result.fail(f"beets would skip it as a duplicate of {earlier} of this run")
                elif result.record["status"] == "ok":
                    passed[result.duplicate_values] = folder
                    result.lines.append("  result    pass")
                print("\n".join(result.lines), flush=True)
                handle.write(SEPARATOR.join(field(result.record[name]) for name in RECORD_FIELDS) + "\n")
                handle.flush()
