# qBittorrent-nox Multi-Profile & Cloudflare Setup Installer

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, complete with **systemd background services** and **Cloudflare Worker 302 Redirectors** (Streamix pattern).

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, and download locations.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-user1.service` and `qbittorrent-user2.service` automatically.
- **Streamix Worker Pattern (302 Redirector)**: Uses a free Cloudflare Worker + KV store to map permanent Worker URLs (`https://qb.workers.dev/user1`) to dynamic `trycloudflare.com` tunnels without exposing bandwidth to Cloudflare or buying a custom domain!

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
│  - qBittorrent Instance 1 (:8080) -> Quick Tunnel 1   │
│  - qBittorrent Instance 2 (:8081) -> Quick Tunnel 2   │
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
│ Access: https://your-worker.workers.dev/user1          │
└────────────────────────────────────────────────────────┘
```

---

## System Specs

| Setting | Profile 1 (Default) | Profile 2 (Default) |
| :--- | :--- | :--- |
| **Web UI Port** | `8080` | `8081` |
| **Peer Listening Port** | `6881` | `6882` |
| **Config Directory** | `~/.config/qBittorrent-user1` | `~/.config/qBittorrent-user2` |
| **Download Folder** | `~/Downloads/user1` | `~/Downloads/user2` |

---

## System Management Commands

Check service status:
```bash
sudo systemctl status qbittorrent-user1
sudo systemctl status qbittorrent-user2
```

View live logs:
```bash
sudo journalctl -u qbittorrent-user1 -f
sudo journalctl -u qbittorrent-user2 -f
```

Restart services:
```bash
sudo systemctl restart qbittorrent-user1 qbittorrent-user2
```

---

## License

MIT License. Free for personal and commercial use.
