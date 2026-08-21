# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood UI + TinyURL Auto-Update)

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, featuring custom Web UIs (**VueTorrent** & **Flood UI**), **systemd background services**, and **TinyURL API Auto-Update**.

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Custom Dual Web UIs**:
  - 🔒 **Private Profile**: Powered by **[VueTorrent](https://github.com/VueTorrent/VueTorrent)** (Modern Vue.js dark mode UI).
  - 🌐 **Public Profile**: Powered by **[Flood UI](https://flood.js.org)** (Node.js & React torrent management suite).
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, passwords, and your existing TinyURL aliases. Automatically detects `~/.tinyurl_env`.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically across reboots.
- **TinyURL API Auto-Update**: Automatically updates your existing TinyURL alias (`tinyurl.com/tbd-qb`) via `PATCH https://api.tinyurl.com/update` whenever systemd restarts or reboots, pointing it to the fresh `trycloudflare.com` tunnel.

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
                            │ (1) Updates existing TinyURL alias on startup
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ TinyURL API (PATCH https://api.tinyurl.com/update)                     │
│ Updates target URL for your existing alias:                            │
│  - tinyurl.com/tbd-qb        -> active Quick Tunnel 1                  │
│  - tinyurl.com/tbd-qb-public -> active Quick Tunnel 2                  │
└───────────────────────────┬────────────────────────────────────────────┘
                            │ (2) Redirects to live Quick Tunnel
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Web Browser / Client                                                   │
│ Access Private: https://tinyurl.com/tbd-qb                             │
│ Access Public:  https://tinyurl.com/tbd-qb-public                      │
└───────────────────────────┴────────────────────────────────────────────┘
```

---

## Default System Specs

| Profile | Web UI Engine | Web UI Port | qBittorrent API Port | TinyURL Alias | Systemd Service |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Private** | **VueTorrent** | `8080` | `8080` | `tinyurl.com/tbd-qb` | `qbittorrent-Private.service` |
| **Public** | **Flood UI** | `3000` | `8090` | `tinyurl.com/tbd-qb-public` | `qbittorrent-Public.service` |

---

## System Management Commands

Check service status:
```bash
sudo systemctl status qbittorrent-Private
sudo systemctl status qbittorrent-Public
```

Restart services:
```bash
sudo systemctl restart qbittorrent-Private qbittorrent-Public
```

---

## License

MIT License. Free for personal and commercial use.
