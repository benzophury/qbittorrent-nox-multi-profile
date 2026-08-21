# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood UI + Cloudflare Tunnels)

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, featuring custom Web UIs (**VueTorrent** & **Flood UI**), **systemd background services**, and **Cloudflare Tunnels**.

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Custom Dual Web UIs**:
  - 🔒 **Private Profile**: Powered by **[VueTorrent](https://github.com/VueTorrent/VueTorrent)** (Modern Vue.js dark mode UI).
  - 🌐 **Public Profile**: Powered by **[Flood UI](https://flood.js.org)** (Node.js & React torrent management suite).
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, and passwords.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically across reboots.
- **Instant Cloudflare Tunnel Access**: Automatically generates secure Cloudflare Quick Tunnel access URLs (`https://*.trycloudflare.com`) on startup and displays them directly in your terminal upon setup completion.

---

## Quick Start

```bash
cd ~/qbittorrent-nox-multi-profile
./setup.sh
```

---

## Default System Specs

| Profile | Web UI Engine | Web UI Port | qBittorrent API Port | Systemd Service |
| :--- | :--- | :--- | :--- | :--- |
| **Private** | **VueTorrent** | `8080` | `8080` | `qbittorrent-Private.service` |
| **Public** | **Flood UI** | `3000` | `8090` | `qbittorrent-Public.service` |

---

## System Management Commands

Check service status:
```bash
pkexec systemctl status qbittorrent-Private
pkexec systemctl status qbittorrent-Public
```

Restart services:
```bash
pkexec systemctl restart qbittorrent-Private qbittorrent-Public
```

---

## License

MIT License. Free for personal and commercial use.
