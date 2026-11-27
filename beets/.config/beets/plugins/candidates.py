"""Adds `beet candidates`. It writes the top album candidates of album folders to a TSV for review.

`beet candidates -o FILE FOLDER...` reads the audio files directly in each folder, looks up
album candidates with the enabled metadata sources, and appends one row per candidate. Folders
already present in FILE are skipped, so an interrupted run resumes.
"""

import csv
import os
import re
import unicodedata

from beets.autotag import Source, tag_album
from beets.library import Item
from beets.plugins import BeetsPlugin
from beets.ui import Subcommand

AUDIO_EXTENSIONS = {
    ".aac", ".aif", ".aiff", ".alac", ".ape", ".flac", ".m4a", ".m4p", ".mp3", ".mp4", ".mpc",
    ".ogg", ".opus", ".wav", ".wma", ".wv",
}
COLUMNS = [
    "folder", "files", "tag_artist", "tag_album", "rank", "similarity", "source", "release_id",
    "artist", "album", "year", "tracks", "unmatched_files", "missing_tracks", "accept",
]


def normalized(text):
    """Returns text casefolded, without accents, and without anything but letters and digits."""
    decomposed = unicodedata.normalize("NFKD", text or "")
    stripped = "".join(c for c in decomposed if not unicodedata.combining(c))
    return re.sub(r"[\W_]+", "", stripped.casefold())


def audio_items(folder):
    """Returns an Item read from each audio file directly in the given folder, sorted by path.
    Files in subfolders are not read."""
    paths = sorted(
        os.path.join(folder, name)
        for name in os.listdir(folder)
        if os.path.splitext(name)[1].lower() in AUDIO_EXTENSIONS
    )
    return [Item.from_path(path) for path in paths]


def done_folders(output):
    """Returns the folders that already have rows in the given TSV output, which permits an
    interrupted invocation to resume."""
    if not os.path.exists(output):
        return set()
    with open(output, newline="", encoding="utf-8") as handle:
        return {row["folder"] for row in csv.DictReader(handle, delimiter="\t")}


def fingerprint(items, log):
    """Looks up each file on AcoustID through the chroma plugin, whose candidates hook then adds
    the releases of the matched recordings."""
    from beetsplug import chroma

    for item in items:
        chroma.acoustid_match(log, item.path)


def candidate_rows(folder, count, log=None):
    """Returns one row per candidate for the given folder, up to the given count. The given log
    is passed to the AcoustID lookup, which happens only if a log is given."""
    items = audio_items(folder)
    if not items:
        return [{"folder": folder, "files": 0, "accept": "", "source": "no audio"}]
    if log is not None:
        fingerprint(items, log)

    source = Source.from_items(items)
    proposal = tag_album(source)
    base = {
        "folder": folder, "files": len(items), "tag_artist": source.artist,
        "tag_album": source.name,
    }
    if not proposal.candidates:
        return [base | {"source": "no candidates", "accept": ""}]

    rows = []
    for rank, match in enumerate(proposal.candidates[:count], start=1):
        info = match.info
        names_equal = (
            normalized(info.artist) == normalized(source.artist)
            and normalized(info.album) == normalized(source.name)
        )
        rows.append(base | {
            "rank": rank,
            "similarity": f"{(1 - float(match.distance)) * 100:.1f}",
            "source": info.data_source,
            "release_id": info.album_id,
            "artist": info.artist,
            "album": info.album,
            "year": info.year or "",
            "tracks": len(info.tracks),
            "unmatched_files": len(match.extra_items),
            "missing_tracks": len(match.extra_tracks),
            # A best candidate whose names equal the tags and which leaves no file unmatched is
            # pre-accepted for the review
            "accept": "y" if rank == 1 and names_equal and not match.extra_items else "",
        })
    return rows


class CandidatesPlugin(BeetsPlugin):
    def commands(self):
        command = Subcommand("candidates", help="write top album candidates of folders to a TSV")
        command.parser.add_option("-o", "--output", help="TSV file to append to")
        command.parser.add_option("-n", "--count", type=int, default=3, help="candidates per folder")
        command.parser.add_option("--fingerprint", action="store_true", help="look files up on AcoustID first")
        command.func = self.run
        return [command]

    def run(self, lib, opts, args):
        done = done_folders(opts.output)
        new_file = not os.path.exists(opts.output)
        with open(opts.output, "a", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(handle, COLUMNS, delimiter="\t", extrasaction="ignore")
            if new_file:
                writer.writeheader()
            for index, folder in enumerate(args, start=1):
                if folder in done:
                    continue
                try:
                    rows = candidate_rows(folder, opts.count, self._log if opts.fingerprint else None)
                except Exception as error:  # A bad file must not stop the other folders
                    rows = [{"folder": folder, "source": f"error: {error}", "accept": ""}]
                writer.writerows(rows)
                handle.flush()
                self._log.info("{}/{} {}", index, len(args), folder)
