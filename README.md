# qBittorrent-nox Multi-Profile & Cloudflare Setup Installer

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, complete with **systemd background services** and **Cloudflare Worker 302 Redirectors** (Streamix pattern).

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, passwords, and download locations.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically.
- **Streamix Worker Pattern (302 Redirector)**: Uses a free Cloudflare Worker + KV store to map permanent Worker URLs (`https://qb.workers.dev/public`) to dynamic `trycloudflare.com` tunnels without exposing bandwidth to Cloudflare or buying a custom domain!

---

## Quick Start

```bash
git clone https://github.com/benzophury/qbittorrent-nox-multi-profile.git
cd qbittorrent-nox-multi-profile
chmod +x setup.sh
./setup.sh
```

---

## Architecture: Streamix Worker 302 Redirect Pattern

```
┌────────────────────────────────────────────────────────┐
│ Runner System (Linux Host)                             │
│  - qBittorrent Private (:8080) -> Quick Tunnel 1       │
│  - qBittorrent Public  (:8090) -> Quick Tunnel 2       │
└───────────────────────────┬────────────────────────────┘
                            │ (1) Auto-syncs live temporary URLs on boot
                            ▼
┌────────────────────────────────────────────────────────┐
│ Cloudflare Worker (your-worker.workers.dev)            │
│  - Stores active TARGET_URLs in Cloudflare KV          │
│  - Secret Key Authentication                           │
└───────────────────────────┬────────────────────────────┘
                            │ (2) HTTP 302 Redirect to live Quick Tunnel
                            ▼
┌────────────────────────────────────────────────────────┐
│ Web Browser / Client                                   │
│ Access: https://your-worker.workers.dev/public         │
└────────────────────────────────────────────────────────┘
```

---

## Default System Specs

| Setting | Private Profile | Public Profile |
| :--- | :--- | :--- |
| **Web UI Port** | `8080` | `8090` |
| **Peer Listening Port** | `6881` | `6882` |
| **Config Directory** | `~/.config/qBittorrent-Private` | `~/.config/qBittorrent-Public` |
| **Download Folder** | `~/Downloads/Private` | `~/Downloads/Public` |

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
