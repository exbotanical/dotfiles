# Wi-Fi troubleshooting

## Measure the current connection

These commands leave the connection unchanged.

```bash
nmcli -t -f NAME,DEVICE connection show --active
nmcli -f IN-USE,SSID,BSSID,CHAN,RATE,SIGNAL dev wifi list --rescan no | rg '^\*'
ip route; ip -6 route
ping -c 5 "$(ip route show default | awk '{print $3; exit}')"   # the access point
ping -4 -c 5 1.1.1.1; ping -6 -c 5 2606:4700:4700::1111          # the internet over each family
curl -4 -s -o /dev/null -w '%{time_connect}s connect\n' https://example.com
curl -6 -s -o /dev/null -m 10 -w '%{time_connect}s connect\n' https://example.com
curl -s -o /dev/null -w 'down %{speed_download} B/s\n' 'https://speed.cloudflare.com/__down?bytes=10000000'
head -c 2000000 /dev/zero | curl -s -o /dev/null -w 'up %{speed_upload} B/s\n' --data-binary @- https://speed.cloudflare.com/__up
```

A low round-trip time to the access point together with a high one to the internet places the delay beyond the access point.

## Read the logs

```bash
sudo journalctl -b -u NetworkManager -u wpa_supplicant \
  | rg -e CTRL-EVENT-DISCONNECTED -e 'link timed out' -e '-> failed' -e 4-Way
sudo journalctl -k -b | rg -i -e timeout -e reset -e firmware
```

- `CTRL-EVENT-DISCONNECTED ... locally_generated=1` means the laptop ended the connection; without `locally_generated`, the access point ended it, and `reason=N` is the IEEE 802.11 reason code.
- `failed (reason 'ssid-not-found')` while the network appears in `nmcli dev wifi list` points at the Wi-Fi driver.
- `failed (reason 'no-secrets')` means the password was rejected; see [passwords.md](passwords.md).
- A NetworkManager process ID that changes between log lines marks a restart of NetworkManager.

## MediaTek MT7925 (mt7925e)

With Wi-Fi power save or PCIe ASPM enabled, this card drops the link and then fails with `ssid-not-found` until NetworkManager is restarted. `root/etc/NetworkManager/conf.d/wifi-powersave-off.conf` and `root/etc/modprobe.d/mt7925e.conf` disable both; install them with `make install_root` and reboot. These commands confirm the settings:

```bash
cat /sys/module/mt7925e/parameters/disable_aspm   # Y
NetworkManager --print-config | rg powersave       # wifi.powersave=2
```

## A network that announces IPv6 without forwarding it

On such a network, `ping -6` loses every packet and `curl -6` times out, while the IPv4 commands succeed. The router announces itself as the IPv6 gateway, so applications that connect over IPv6 first stall on every new connection. An application that races IPv6 against IPv4 (Happy Eyeballs, RFC 8305) falls back after about 250 ms; one that does not waits for the TCP connect timeout, 127 seconds with the default `net.ipv4.tcp_syn_retries` of 6. Disable IPv6 on that network's profile as [profiles.md](profiles.md) describes.
