# 🔐 CI/CD Pipeline for Automated VPN Deployment

> Automate WireGuard VPN deployment using GitHub Actions — from commit to live server in seconds.

---

## 📌 Project Overview

This project implements a **CI/CD pipeline** that automatically deploys a **WireGuard VPN** server whenever configuration changes are pushed to the repository.

**No manual SSH. No manual install. Just commit → push → done.**

---

## 🧰 Technologies Used

| Tool           | Role                              |
|----------------|-----------------------------------|
| WireGuard      | VPN solution (fast, modern)       |
| GitHub Actions | CI/CD pipeline automation         |
| Ubuntu Server  | Target deployment environment     |
| Bash Scripts   | Install, test, and deploy VPN     |
| SSH            | Secure remote server access       |

---

## 🏗️ Architecture

```
Developer
   |
   | git commit + push
   v
GitHub Repository
   |
   v
GitHub Actions Pipeline
   |
   ├── 1. Validate WireGuard config syntax
   ├── 2. Run config tests
   ├── 3. Connect to server via SSH
   └── 4. Install & activate WireGuard
         |
         v
   Ubuntu VPN Server (wg0 interface UP)
```

---

## 📁 Project Structure

```
vpn-cicd-project/
│
├── README.md                        ← This file
├── configs/
│   └── wg0.conf.example             ← WireGuard config template
│
├── scripts/
│   ├── install_wireguard.sh         ← Install WireGuard on Ubuntu
│   ├── test_config.sh               ← Validate config before deploy
│   └── deploy_vpn.sh                ← Deploy config to server
│
└── .github/
    └── workflows/
        └── deploy-vpn.yml           ← GitHub Actions pipeline
```

---

## ⚙️ Setup Instructions

### 1. Prerequisites
- Ubuntu 20.04+ server with SSH access
- GitHub repository (this project)
- GitHub Secrets configured (see below)

### 2. GitHub Secrets Required

Go to **Settings → Secrets → Actions** and add:

| Secret Name        | Value                              |
|--------------------|------------------------------------|
| `VPN_SERVER_IP`    | Your server's IP address           |
| `VPN_SERVER_USER`  | SSH username (e.g., `ubuntu`)      |
| `SSH_PRIVATE_KEY`  | Your private SSH key content       |
| `WG_PRIVATE_KEY`   | WireGuard server private key       |
| `WG_PUBLIC_KEY`    | WireGuard server public key        |

### 3. Generate WireGuard Keys

```bash
# On your server:
wg genkey | tee server_privatekey | wg pubkey > server_publickey
cat server_privatekey   # → copy to WG_PRIVATE_KEY secret
cat server_publickey    # → copy to WG_PUBLIC_KEY secret
```

### 4. Push & Deploy

```bash
git add .
git commit -m "deploy: update VPN config"
git push origin main
```

→ GitHub Actions will automatically run the pipeline.

---

## 🧪 Testing Locally

```bash
# Validate config syntax
bash scripts/test_config.sh

# Manual install (on the server)
bash scripts/install_wireguard.sh

# Manual deploy (on the server)
bash scripts/deploy_vpn.sh
```

---

## 📅 Project Timeline (2 Days)

### Day 1 — Setup & Structure
- [x] Understand the project architecture
- [x] Create project folder structure
- [x] Write all scripts and configs
- [ ] Test WireGuard commands locally

### Day 2 — Pipeline & Delivery
- [ ] Configure GitHub Actions pipeline
- [ ] Test automated deployment via SSH
- [ ] Run end-to-end tests
- [ ] Prepare report + slides + demo

---

## 📄 Deliverables

- ✅ Working CI/CD pipeline (GitHub Actions)
- ✅ Automated VPN deployment scripts
- ✅ Technical report (PDF)
- ✅ Presentation slides
- ✅ Live demo

---

## 👨‍💻 Author

**Project:** CI/CD for VPN Deployment  
**Context:** DevOps academic project  
**Duration:** 2 days
