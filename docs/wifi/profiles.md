# Wi-Fi profiles

NetworkManager keeps one profile per saved network. On Arch, a profile created through NetworkManager is a keyfile in `/etc/NetworkManager/system-connections/`; on Ubuntu 24.04, NetworkManager writes it through netplan to `/etc/netplan/90-NM-<uuid>.yaml`. `nmcli` commands are the same on both. A profile an administrator installs is also a keyfile in `/etc/NetworkManager/system-connections/`, so the directory alone does not identify who created a profile.

## List profiles

```bash
nmcli -f NAME,TYPE,AUTOCONNECT,TIMESTAMP-REAL connection show | rg -e NAME -e wireless
nmcli -f NAME,FILENAME connection show
```

`TIMESTAMP-REAL` is the time of the last successful connection, and `never` marks a profile that has never connected.

## Choose which networks autoconnect

`wifi_autoconnect` sets autoconnect on every Wi-Fi profile from two machine-local files of bash glob patterns, one per line, with `#` comments:

- `~/.config/wifi/autoconnect` lists the profiles that autoconnect.
- `~/.config/wifi/unmanaged` lists the profiles the script leaves unchanged, such as ones an administrator installs.

The script sets every other Wi-Fi profile to not autoconnect, prints each change, and runs each change through sudo. The files are kept out of the repo because they name private networks. A literal `*`, `?`, or `[` in a profile name is escaped with `\`.

Run `wifi_autoconnect` after saving a new network, because a network missing from both files stops autoconnecting. Changing autoconnect leaves the active connection up.

## Delete a profile

```bash
sudo nmcli connection delete id '<name>'
```

An open network with autoconnect on joins any access point that broadcasts the same name, so delete open-network profiles that are no longer used.

## Disable IPv6 on one network

```bash
sudo nmcli connection modify id '<name>' ipv6.method disabled
```

The change applies at the next connection to that network. [troubleshooting.md](troubleshooting.md) describes the symptom that calls for it.
