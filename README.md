# 🛒 IT Groceries Shop - Ultimate Installer

![Platform](https://img.shields.io/badge/Platform-Windows_10%2F11-blue?style=for-the-badge&logo=windows)
![Language](https://img.shields.io/badge/Script-PowerShell_%26_Batch-green?style=for-the-badge&logo=powershell)
![License](https://img.shields.io/badge/License-MIT-orange?style=for-the-badge)

<img width="1322" height="644" alt="ScreenshotsAiO" src="https://github.com/user-attachments/assets/bd6817ce-846e-463e-87d1-2e320fc7e258" />

**The Ultimate Cloud-Based Software Deployment Tool.** A lightweight, portable, and automated installer designed for system administrators and IT professionals. No installation required—just run and deploy.

---

## 🚀 Quick Start (One-Liner)
Run the following command in **PowerShell (Run as Administrator)** to launch the installer directly from the cloud:

```powershell
iex (irm bit.ly/itgaio)
```
Note: The script will automatically download the necessary components to your temporary folder, execute the menu, and clean up everything after you exit.

## ✨ Key Features

* **☁️ Cloud-Native:** Always fetches the latest scripts and database from the repository.
* **⚡ Turbo Download:** Integrated with `aria2c` for high-speed, multi-connection downloads (up to 16 threads).
* **🛡️ Smart Bridge System:** Isolate execution environment. Scripts run safely in `%TEMP%` without leaving junk in your system.
* **🔇 Silent Installation:** All software packages are installed in silent mode (no user interaction required).
* **🔧 Network Optimized:** Includes fixes for IPv6 issues and anti-file-renaming logic for stability.

---

## 📦 Supported Software Categories

This tool automates the download and installation of popular **Freeware** and **Open Source** software:

| Category | Examples |
| :--- | :--- |
| **Browsers** | Google Chrome, Mozilla Firefox, Microsoft Edge |
| **Communication** | LINE PC, Zoom, Discord, Microsoft Teams |
| **Multimedia** | VLC Media Player, PotPlayer |
| **Utilities** | 7-Zip, AnyDesk, CPU-Z |
| **Office** | LibreOffice, PDF Readers |

---

## 🛠️ Requirements

* **OS:** Windows 10 or Windows 11 (x64 recommended)
* **Shell:** PowerShell 5.1 or later
* **Permission:** Administrator privileges are required to install software.
* **Internet:** Stable internet connection is required for downloading packages.

---

## ⚠️ Disclaimer & Legal

This repository contains **automation scripts** (`.ps1`, `.cmd`) designed to facilitate the downloading and installation of software.

1.  **No Binary Hosting:** This repository **does not host** any proprietary software binaries, installers, or copyrighted executable files. All software is downloaded directly from official sources or authorized mirrors during runtime.
2.  **Compliance:** This tool is intended for **Freeware** and **Open Source** software management. Users are responsible for adhering to the End User License Agreements (EULA) of the respective software being installed.
3.  **No Warranty:** This software is provided "as is", without warranty of any kind. Use it at your own risk.

---

### 👨‍💻 Maintainer

**IT Groceries Shop**
*Automating your IT life, one script at a time.*
