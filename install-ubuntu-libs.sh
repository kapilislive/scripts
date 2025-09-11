#!/bin/bash
set -e

# ============================
# Ubuntu Server Setup Script
# Modular - Choose what to install
# ============================

# --- Safety checks ---
if ! command -v sudo &>/dev/null; then
    echo "❌ sudo not found. Please install it first."
    exit 1
fi

# --- Functions ---
update_system() {
    echo "🔄 Updating system..."
    sudo apt update && sudo apt upgrade -y
}

install_common_tools() {
    echo "🔧 Installing common tools..."
    sudo apt install -y curl wget git unzip ufw build-essential
}

disable_sleep() {
    echo "🖥️ Disabling sleep on lid close..."
    sudo tee /etc/systemd/logind.conf >/dev/null <<EOL
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
IdleAction=ignore
HandleListSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
LidSwitchIgnoreInhibited=no
EOL
    sudo systemctl restart systemd-logind
}

install_node() {
    echo "⬇️ Installing Node.js (LTS)..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt install -y nodejs
    node -v
    npm -v
}

install_ollama() {
    echo "⬇️ Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    ollama pull gemma3:1b
    ollama serve
}

install_docker() {
    echo "🐳 Installing Docker..."
    sudo apt install -y ca-certificates gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker "$USER"
    docker --version
    echo "👉 Log out and log back in for Docker group changes to apply."
}

setup_firewall() {
    echo "🔥 Setting up UFW firewall..."
    sudo ufw allow OpenSSH
    sudo ufw allow 80
    sudo ufw allow 443
    if ! sudo ufw status | grep -q "Status: active"; then
        sudo ufw --force enable
    fi
    sudo ufw status
}

install_jitsi() {
    echo "📹 Installing Jitsi Meet..."
    sudo apt install -y apt-transport-https
    curl https://download.jitsi.org/jitsi-key.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/jitsi-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/" | \
      sudo tee /etc/apt/sources.list.d/jitsi-stable.list
    sudo apt update
    sudo apt install -y jitsi-meet
    echo "➡️ Run: sudo /usr/share/jitsi-meet/scripts/install-letsencrypt-cert.sh for SSL"
}

# --- Menu ---
echo "=================================="
echo " Ubuntu Setup Script"
echo "=================================="
echo "1) Update system"
echo "2) Install common tools"
echo "3) Install Node.js"
echo "4) Install Docker"
echo "5) Setup Firewall"
echo "6) Install Jitsi Meet"
echo "7) Disable sleep on lid close"
echo "8) Install Ollama"
echo "=================================="

# Support both interactive & automation mode
if [ $# -gt 0 ]; then
    choices="$@"
else
    read -rp "Enter choices (e.g. 1 2 4): " choices < /dev/tty
fi

for choice in $choices; do
    case $choice in
        1) update_system ;;
        2) install_common_tools ;;
        3) install_node ;;
        4) install_docker ;;
        5) setup_firewall ;;
        6) install_jitsi ;;
        7) disable_sleep ;;
        8) install_ollama ;;
        *) echo "❌ Invalid option: $choice" ;;
    esac
done

echo "✅ Setup complete!"