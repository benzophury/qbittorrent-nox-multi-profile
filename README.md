# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood UI + TinyURL API)

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, featuring custom Web UIs (**VueTorrent** & **Flood UI**), **systemd background services**, and **TinyURL API Link Generation**.

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Custom Dual Web UIs**:
  - 🔒 **Private Profile**: Powered by **[VueTorrent](https://github.com/VueTorrent/VueTorrent)** (Modern Vue.js dark mode UI).
  - 🌐 **Public Profile**: Powered by **[Flood UI](https://flood.js.org)** (Node.js & React torrent management suite).
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, and passwords. Automatically detects `~/.tinyurl_env`.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically across reboots.
- **TinyURL API Generation**: Automatically generates fresh TinyURL short links via the TinyURL API whenever systemd restarts or reboots, and logs them to `~/.config/qBittorrent-Private/current_tinyurl.txt` and `~/.config/qBittorrent-Public/current_tinyurl.txt`.

---

## Quick Start

```bash
cd ~/qbittorrent-nox-multi-profile
./setup.sh
```

---

## Default System Specs

| Profile | Web UI Engine | Web UI Port | qBittorrent API Port | Config Directory | Systemd Service |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Private** | **VueTorrent** | `8080` | `8080` | `~/.config/qBittorrent-Private` | `qbittorrent-Private.service` |
| **Public** | **Flood UI** | `3000` | `8090` | `~/.config/qBittorrent-Public` | `qbittorrent-Public.service` |

---

## System Management Commands

Check service status:
```bash
sudo systemctl status qbittorrent-Private
sudo systemctl status qbittorrent-Public
```

View live TinyURL links:
```bash
cat ~/.config/qBittorrent-Private/current_tinyurl.txt
cat ~/.config/qBittorrent-Public/current_tinyurl.txt
```

Restart services:
```bash
sudo systemctl restart qbittorrent-Private qbittorrent-Public
```

---

## License

MIT License. Free for personal and commercial use.
