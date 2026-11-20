# Wi-Fi passwords

## Read a saved password

```bash
sudo nmcli -s -g 802-11-wireless-security.psk connection show id '<name>'
```

Reading or changing a system-wide profile (`psk-flags` 0) requires root or a polkit grant, and polkit rules differ by distribution, so the commands here use sudo. Without either, nmcli prints an empty password.

## Change a saved password

```bash
 sudo nmcli connection modify id '<name>' wifi-sec.psk '<password>'
```

The new password applies at the next connection, and the active connection stays up. Bash leaves a command that starts with a space out of history when `HISTCONTROL` contains `ignorespace` or `ignoreboth`.

To enter the password at a prompt and connect at once, run `nmcli --ask connection up id '<name>'`; this replaces the active connection.

## Recognize a rejected password

When the access point rejects the saved password, NetworkManager logs a `need-auth -> failed (reason 'no-secrets')` state change for the Wi-Fi device:

```bash
sudo journalctl -b -u NetworkManager | rg "no-secrets"
```
