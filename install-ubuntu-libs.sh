#!/bin/bash
set -e

# ============================
# Ubuntu Server Setup Script
# Modular - Choose what to install
# ============================

# Function: Update system
update_system() {
    echo "🔄 Updating system..."
    sudo apt update && sudo apt upgrade -y
}

# Function: Install common tools
install_common_tools() {
    echo "🔧 Installing common tools..."
    sudo apt install -y curl wget git unzip ufw build-essential
}

disableSleepOnLidClose() {
    echo "🖥️ Disabling sleep on lid close..."
    sudo systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
    sudo sed -i 's/^#*\(HandleSuspendKey=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(HandleHibernateKey=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(HandleLidSwitch=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(IdleAction=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(HandleListSwitchExternalPower=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(HandleLidSwitchDocked=\).*/\1ignore/' /etc/systemd/logind.conf
    sudo sed -i 's/^#*\(LidSwitchIgnoreInhibited=\).*/\1no/' /etc/systemd/logind.conf
}

# Function: Install Node.js LTS
install_node() {
    echo "⬇️ Installing Node.js (LTS)..."
    sudo apt install -y nodejs
    node -v
    npm -v
}

# Function: Install Docker
install_docker() {
    echo "🐳 Installing Docker..."
    sudo apt install -y ca-certificates gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) \
      signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    docker --version
}

# Function: Configure Firewall
setup_firewall() {
    echo "🔥 Setting up UFW firewall..."
    sudo ufw allow OpenSSH
    sudo ufw allow 80
    sudo ufw allow 443
    sudo ufw --force enable
    sudo ufw status
}

# Function: Install Jitsi Meet (basic)
install_jitsi() {
    echo "📹 Installing Jitsi Meet..."
    sudo apt install -y apt-transport-https
    curl https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | sudo tee /etc/apt/sources.list.d/jitsi-stable.list
    sudo apt update
    sudo apt install -y jitsi-meet
    echo "➡️ Run: sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh for SSL"
}

# ============================
# Menu System
# ============================
echo "=================================="
echo " Ubuntu Setup Script"
echo "=================================="
echo "Select options (space separated):"
echo "1) Update system"
echo "2) Install common tools"
echo "3) Install Node.js"
echo "4) Install Docker"
echo "5) Setup Firewall"
echo "6) Install Jitsi Meet"
echo "7) Disable sleep on lid close"
echo "=================================="

read -p "Enter choices (e.g. 1 2 4): " choices

for choice in $choices; do
    case $choice in
        1) update_system ;;
        2) install_common_tools ;;
        3) install_node ;;
        4) install_docker ;;
        5) setup_firewall ;;
        6) install_jitsi ;;
        7) disableSleepOnLidClose ;;
        *) echo "❌ Invalid option: $choice" ;;
    esac
done

echo "✅ Setup complete!"