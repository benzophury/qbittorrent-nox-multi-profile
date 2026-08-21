# qBittorrent-nox Multi-Profile & Cloudflare Tunnel Installer

An automated, interactive installer to set up **multiple isolated qBittorrent-nox instances** (profiles) on Linux, complete with **systemd background services** and **Cloudflare Tunnel / Worker routing templates**.

---

## Features

- **Multi-Profile Isolation**: Run 2 or more independent `qbittorrent-nox` instances with separate logins, WebUI ports, peer ports, download directories, and torrent lists.
- **Interactive Terminal Installer (`setup.sh`)**: One-command interactive setup prompting for custom ports, usernames, and download locations.
- **Automated Systemd Services**: Creates, enables, and manages `qbittorrent-user1.service` and `qbittorrent-user2.service` automatically.
- **Cloudflare Ready**: Includes Cloudflare Tunnel ingress configs (`cloudflared-ingress-config.yml`) and Cloudflare Worker routing script (`cloudflare/worker-router.js`) for secure remote access without opening router ports.

---

## Quick Start

```bash
git clone https://github.com/benzophury/qbittorrent-nox-multi-profile.git
cd qbittorrent-nox-multi-profile
chmod +x setup.sh
./setup.sh
```

---

## How It Works

`qbittorrent-nox` natively supports the `--profile` flag to isolate settings and sessions.

```
[ Internet User 1 ] ---> user1-qb.yourdomain.com ---> [ Cloudflare Tunnel ] ---> localhost:8080 (Profile 1)
[ Internet User 2 ] ---> user2-qb.yourdomain.com ---> [ Cloudflare Tunnel ] ---> localhost:8081 (Profile 2)
```

### System Specs

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

## Cloudflare Tunnel & Worker Setup

1. **Install `cloudflared`**: Follow Cloudflare's official guide to install `cloudflared`.
2. **Use Generated Ingress Config**: Use the generated `cloudflared-ingress-config.yml` template to route subdomains to `localhost:8080` and `localhost:8081`.
3. **Cloudflare Access (Zero Trust)**: Protect both URLs behind Google/Email login walls via Cloudflare Zero Trust Dashboard $\rightarrow$ Access Applications.

---

## License

MIT License. Free for personal and commercial use.
