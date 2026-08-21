# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood UI + TinyURL Auto-Sync)

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, featuring custom Web UIs (**VueTorrent** & **Flood UI**), **systemd background services**, and **TinyURL API Auto-Sync**.

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Custom Dual Web UIs**:
  - 🔒 **Private Profile**: Powered by **[VueTorrent](https://github.com/VueTorrent/VueTorrent)** (Modern Vue.js dark mode UI).
  - 🌐 **Public Profile**: Powered by **[Flood UI](https://flood.js.org)** (Node.js & React torrent management suite).
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, passwords, and custom TinyURL aliases.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically across reboots.
- **TinyURL API Auto-Sync**: Automatically updates your custom TinyURL links (`tinyurl.com/private-qb` and `tinyurl.com/public-qb`) via the TinyURL API whenever systemd restarts or reboots!

---

## Quick Start

```bash
cd ~/qbittorrent-nox-multi-profile
./setup.sh
```

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│ Runner System (Linux Host)                                             │
│  - Private Profile (:8080) VueTorrent -> Quick Tunnel 1                │
│  - Public Profile  (:3000) Flood UI   -> Quick Tunnel 2                │
└───────────────────────────┬────────────────────────────────────────────┘
                            │ (1) Auto-syncs live temporary URLs via TinyURL API
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ TinyURL API (https://api.tinyurl.com)                                  │
│ Updates custom aliases:                                                │
│  - tinyurl.com/private-qb -> active Quick Tunnel 1                     │
│  - tinyurl.com/public-qb  -> active Quick Tunnel 2                     │
└───────────────────────────┬────────────────────────────────────────────┘
                            │ (2) Redirects to live Quick Tunnel
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Web Browser / Client                                                   │
│ Access Private: https://tinyurl.com/private-qb                         │
│ Access Public:  https://tinyurl.com/public-qb                          │
└───────────────────────────┴────────────────────────────────────────────┘
```

---

## Default System Specs

| Profile | Web UI Engine | Web UI Port | qBittorrent API Port | TinyURL Alias | Systemd Service |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Private** | **VueTorrent** | `8080` | `8080` | `tinyurl.com/private-qb` | `qbittorrent-Private.service` |
| **Public** | **Flood UI** | `3000` | `8090` | `tinyurl.com/public-qb` | `qbittorrent-Public.service` |

---

## System Management Commands

Check service status:
```bash
sudo systemctl status qbittorrent-Private
sudo systemctl status qbittorrent-Public
```

View live logs:
```bash
sudo journalctl -u qbittorrent-Private -f
sudo journalctl -u qbittorrent-Public -f
```

Restart services:
```bash
sudo systemctl restart qbittorrent-Private qbittorrent-Public
```

---

## License

MIT License. Free for personal and commercial use.
