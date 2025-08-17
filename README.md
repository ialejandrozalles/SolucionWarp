# 🚀 Warp Terminal Docker - Professional Portable Edition

<div align="center">

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()
[![Platform](https://img.shields.io/badge/platform-Linux-orange.svg)]()
[![Docker](https://img.shields.io/badge/docker-required-blue.svg)]()

**Professional containerized Warp Terminal with X11 support and SSH capabilities**  
*Fully portable across any Linux system with Docker*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)  
- [Requirements](#-requirements)
- [Quick Start](#-quick-start)
- [Usage](#-usage)
- [Portability Guide](#-portability-guide)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Advanced Usage](#-advanced-usage)

---

## 🎯 Overview

This project provides a **professional, portable, and production-ready** solution to run Warp Terminal in a Docker container with full X11 graphical support and SSH capabilities. It automatically configures itself for any Linux user and system.

### Why Use This?

- **🔐 Security**: Isolated environment with controlled permissions
- **🚀 Portability**: Works on any Linux system with Docker
- **⚡ Performance**: Optimized container with minimal overhead
- **🛠 SSH Support**: Full SSH client/server capabilities included
- **🔧 Auto-Configuration**: Zero manual setup required
- **🎨 Native Graphics**: Full X11 support with GPU acceleration

---

## ✨ Features

### Core Features
- ✅ **Full Warp Terminal** with all native features
- ✅ **X11 Graphics Support** with hardware acceleration
- ✅ **SSH Client & Server** for remote connections
- ✅ **Auto User Mapping** (UID/GID match host)
- ✅ **Automatic X11 Configuration** (DISPLAY, .Xauthority)
- ✅ **Network Tools** (ping, telnet, netcat, rsync)

### Developer Tools Included
- ✅ **Git** for version control
- ✅ **Vim/Nano** text editors  
- ✅ **Development Tools** (strace, gdb, htop)
- ✅ **Archive Utilities** (zip, unzip, tar)
- ✅ **System Monitoring** (tree, htop, net-tools)

### Professional Features
- ✅ **Zero Configuration** - works out of the box
- ✅ **Fully Portable** - copy to any Linux system
- ✅ **Smart Cleanup** - automatic container management
- ✅ **Error Handling** - robust error recovery
- ✅ **Multi-Mode Support** - build/rebuild/clean/shell modes

---

## 📋 Requirements

### Mandatory
- **Linux OS** (Ubuntu, Debian, Fedora, Arch, etc.)
- **Docker or Podman** installed and running
- **X11 Server** (pre-installed on most Linux desktops)

### System Resources
- **RAM**: 2GB free (1.2GB for Docker image)
- **Disk**: 3GB free space
- **CPU**: Any modern x86_64 processor

### Supported Distributions
| Distribution | Version | Status |
|-------------|---------|---------|
| Ubuntu | 18.04+ | ✅ Fully Supported |
| Debian | 10+ | ✅ Fully Supported |
| Fedora | 30+ | ✅ Fully Supported |
| CentOS/RHEL | 8+ | ✅ Fully Supported |
| Arch Linux | Rolling | ✅ Fully Supported |
| openSUSE | 15+ | ✅ Fully Supported |

---

## 🚀 Quick Start

### Option 1: Full Automatic (Recommended)
```bash
# Download Warp Terminal package if needed
./setup.sh

# Build and run in one command
./warp.sh
```

### Option 2: Manual Control
```bash
# 1. Download Warp Terminal
./setup.sh

# 2. Build Docker image  
./build.sh

# 3. Run Warp Terminal
./warp.sh
```

### Option 3: One-Line Installation
```bash
# Download, build, and run
./warp.sh build
```

**That's it!** Warp Terminal will appear on your desktop in a few seconds.

---

## 💻 Usage

### Basic Commands

```bash
# Run Warp Terminal (automatic mode)
./warp.sh

# Build image first, then run
./warp.sh build

# Force rebuild and run
./warp.sh rebuild  

# Clean system and run
./warp.sh clean

# Run bash shell instead of Warp Terminal
./warp.sh shell

# Show help
./warp.sh --help
```

### SSH Usage Inside Container

```bash
# Start bash in container
./warp.sh shell

# Inside container, use SSH normally:
ssh user@remote-server
scp file.txt user@server:/path/
rsync -av folder/ user@server:/backup/
```

### Advanced Building

```bash
# Build with custom options
./build.sh --force --clean --verbose

# Build with custom image name
./build.sh --name my-warp --tag v1.0
```

---

## 📦 Portability Guide

### Copying to Another System

1. **Create portable copy:**
   ```bash
   # Copy entire project
   cp -r warp-docker /media/usb/
   ```

2. **On target system:**
   ```bash
   # Copy from USB
   cp -r /media/usb/warp-docker ~/
   cd ~/warp-docker
   
   # Set permissions
   chmod +x *.sh
   
   # Run automatic setup
   ./warp.sh build
   ```

### What Transfers
- ✅ **All scripts** (automatically adapt to new user)
- ✅ **Docker configuration** (uses dynamic user detection)
- ✅ **Warp Terminal package** (40MB .deb file included)
- ✅ **Documentation** (this README)

### What Auto-Configures
- ✅ **Username/UID/GID** (matches target system user)
- ✅ **X11 Configuration** (DISPLAY, .Xauthority)
- ✅ **File Permissions** (automatically set)
- ✅ **Docker Networks** (host network mode)

---

## ⚙️ Configuration

### Environment Variables

The container automatically configures these variables:

```bash
DISPLAY=:0                    # X11 display
HOME=/home/username           # User home (dynamic)
USER=username                # Username (dynamic) 
QT_X11_NO_MITSHM=1           # Graphics optimization
_X11_NO_MITSHM=1             # Graphics optimization
XLIB_SKIP_ARGB_VISUALS=1     # Compatibility fix
```

### Docker Configuration

```yaml
# Network: Host mode (full network access)
network_mode: host

# Capabilities: SYS_ADMIN (required for GUI apps)
cap_add: SYS_ADMIN

# Volumes:
volumes:
  - /tmp/.X11-unix:/tmp/.X11-unix:rw    # X11 socket
  - ~/.Xauthority:/tmp/.X11-auth:ro     # X11 auth
  - /dev/shm:/dev/shm                   # Shared memory
  - /etc/localtime:/etc/localtime:ro    # Timezone sync
```

### GPU Acceleration

If available, GPU devices are automatically mounted:
```bash
# Auto-detected and mounted
--device=/dev/dri
```

---

## 🔧 Troubleshooting

### Common Issues

#### 🚫 "Docker not found"
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install docker.io

# Fedora
sudo dnf install docker

# Arch Linux  
sudo pacman -S docker

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

#### 🚫 "Permission denied" 
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply changes (logout/login or run):
newgrp docker
```

#### 🚫 "X11 connection refused"
```bash
# Set DISPLAY variable
export DISPLAY=:0

# Allow local connections
xhost +local:

# Then run again:
./warp.sh
```

#### 🚫 "Build failed"
```bash
# Clean rebuild
./warp.sh rebuild

# Or manual cleanup:
docker system prune -f
./build.sh --force --clean
```

#### 🚫 "No space left on device"
```bash
# Clean Docker system
docker system prune -f
docker image prune -f

# Remove old images
docker images | grep '<none>' | awk '{print $3}' | xargs docker rmi
```

### Debug Mode

Enable verbose logging:
```bash
# Build with verbose output
./build.sh --verbose

# Check Docker logs
docker logs warp-terminal

# Run system diagnostics (if available)
./check-system.sh  # If you kept this file
```

### Network Connectivity

Test SSH connections:
```bash
# Test basic connectivity
ping google.com

# Test SSH inside container
./warp.sh shell
ssh -T git@github.com  # Test Git over SSH
```

---

## 🏗 Advanced Usage

### Custom Volumes

Mount additional directories:
```bash
# Edit warp.sh and add:
docker_cmd="$docker_cmd -v /home/user/projects:/workspace"
docker_cmd="$docker_cmd -v /etc/ssh:/etc/ssh:ro"
```

### Persistent Configuration

Create persistent storage:
```bash
# Create volumes for persistent data
docker volume create warp-config
docker volume create warp-ssh-keys

# Mount in container (edit warp.sh):
-v warp-config:/home/user/.config
-v warp-ssh-keys:/home/user/.ssh
```

### Custom Image Building

Build with custom base or packages:
```bash
# Edit Dockerfile to add packages:
RUN apt-get install -y your-package-here

# Build with custom name:
./build.sh --name warp-custom --tag dev
```

### Integration with CI/CD

Use in automated environments:
```bash
# Non-interactive mode
DISPLAY=:99 xvfb-run ./warp.sh shell -c "your-commands"

# Docker-in-Docker
docker run --privileged -v /var/run/docker.sock:/var/run/docker.sock
```

---

## 📁 Project Structure

```
warp-docker/
├── 🚀 warp.sh              # Main launcher (auto-everything)
├── 🏗️ build.sh             # Docker image builder
├── 🐳 Dockerfile           # Container configuration
├── ⚙️ entrypoint.sh         # Container entry point
├── 📥 setup.sh              # Warp Terminal downloader
├── 📦 warp-terminal.deb     # Warp Terminal package (40MB)
└── 📖 README.md             # This documentation
```

### File Sizes
- **Scripts**: ~30KB total
- **Warp Package**: ~40MB
- **Built Image**: ~1.2GB
- **Total Project**: ~1.3GB

---

## 🔒 Security Considerations

### Container Security
- ✅ **Non-root user** inside container
- ✅ **Limited capabilities** (only SYS_ADMIN for GUI)
- ✅ **Isolated filesystem** (no access to host files by default)
- ✅ **Controlled network access** (host network for SSH)

### X11 Security  
- ✅ **Temporary xhost permissions** (auto-cleaned on exit)
- ✅ **Local-only access** (`xhost +local:`)
- ✅ **Secure .Xauthority handling**

### SSH Security
- ✅ **SSH keys isolated** in container
- ✅ **No permanent SSH server** (client-only by default)
- ✅ **Network isolation** options available

---

## 🤝 Contributing

This is a professional-grade, production-ready project. Contributions welcome:

1. **Bug Reports**: Open issues with detailed reproduction steps
2. **Feature Requests**: Propose enhancements with use cases
3. **Pull Requests**: Follow existing code style and patterns
4. **Documentation**: Improve this README or add guides

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

## 🎉 Success! 

Your **Warp Terminal Docker Professional Portable Edition** is ready to use!

```bash
# Start using it now:
./warp.sh
```

**Enjoy your containerized Warp Terminal with full SSH capabilities! 🚀**

---

<div align="center">

**Made with ❤️ for the Linux community**

*Portable • Professional • Production-Ready*

</div>
