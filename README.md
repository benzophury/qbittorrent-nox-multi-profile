# qBittorrent-nox Multi-Profile AIO Installer (VueTorrent + Flood UI)

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, featuring custom Web UIs (**VueTorrent** & **Flood UI**), **systemd background services**, automatic browser launchers (**Firefox Nightly** & **LibreWolf**), and **Cloudflare Worker 302 Redirectors** (Streamix pattern).

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances (`Private` & `Public`) with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Custom Dual Web UIs & Auto Browser Launchers**:
  - 🔒 **Private Profile**: Powered by **[VueTorrent](https://github.com/VueTorrent/VueTorrent)** (Modern Vue.js dark mode UI) $\rightarrow$ Auto-launches in **Firefox Nightly**.
  - 🌐 **Public Profile**: Powered by **[Flood UI](https://flood.js.org)** (Node.js & React torrent management suite) $\rightarrow$ Auto-launches in **LibreWolf**.
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, passwords, and download locations.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-Private.service` and `qbittorrent-Public.service` automatically across reboots.
- **Streamix Worker Pattern (302 Redirector)**: Uses a free Cloudflare Worker + KV store to map permanent Worker URLs (`https://qb.workers.dev/private` and `/public`) to dynamic `trycloudflare.com` tunnels without exposing bandwidth to Cloudflare or buying a custom domain!

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
│  - Private Profile (:8080) VueTorrent -> Quick Tunnel 1 -> Firefox     │
│  - Public Profile  (:3000) Flood UI   -> Quick Tunnel 2 -> LibreWolf   │
└───────────────────────────┬────────────────────────────────────────────┘
                            │ (1) Auto-syncs live temporary URLs on boot
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Cloudflare Worker (your-worker.workers.dev)                            │
│  - Stores active TARGET_URLs in Cloudflare KV                          │
│  - Secret Key Authentication                                           │
└───────────────────────────┬────────────────────────────────────────────┘
                            │ (2) HTTP 302 Redirect to live Quick Tunnel
                            ▼
┌────────────────────────────────────────────────────────────────────────┐
│ Web Browser / Client                                                   │
│ Access Private: https://your-worker.workers.dev/private                │
│ Access Public:  https://your-worker.workers.dev/public                 │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Default System Specs

| Profile | Web UI Engine | Web UI Port | Target Browser | Config Directory | Systemd Service |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Private** | **VueTorrent** | `8080` | **Firefox Nightly** | `~/.config/qBittorrent-Private` | `qbittorrent-Private.service` |
| **Public** | **Flood UI** | `3000` | **LibreWolf** | `~/.config/qBittorrent-Public` | `qbittorrent-Public.service` |

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
