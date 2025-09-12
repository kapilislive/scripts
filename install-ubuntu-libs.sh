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

install_pm2() {
    echo "⬇️ Installing PM2..."
    sudo npm install -g pm2
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
    sleep 4;
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

install_mongodb() {
    echo "⬇️ Installing MongoDB..."
    sudo apt-get install gnupg curl
    curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
    sudo apt-get update
    sudo apt-get install -y mongodb-org
    sudo systemctl start mongod
    sudo systemctl enable mongod
    sudo systemctl status mongod
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

install_cockpit() {
    echo "🖥️ Installing Cockpit (Web Admin UI)..."
    sudo apt update
    sudo apt install -y cockpit

    echo "🚀 Enabling Cockpit service..."
    sudo systemctl enable --now cockpit.socket

    echo "✅ Cockpit installed and running."
    echo "👉 Access it at: https://$(hostname -I | awk '{print $1}'):9090"
}

install_docker() {
    echo "🐳 Setting Up Docker Repo..."
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    echo "Installing Docker..."
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo "Docker installed successfully."
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

install_tailscale() {
    echo "🛜 Installing Tailscale..."
    curl -fsSL https://tailscale.com/install.sh | sh
    echo "🚀 Starting Tailscale service..."
    sudo systemctl enable --now tailscaled
    echo "🔑 Authenticate with Tailscale..."
    sudo tailscale up --ssh
}

setup_tailscale_funnel() {
    if [ -z "$1" ]; then
        read -rp "Enter port to expose with Tailscale Funnel (e.g. 80, 3000): " FUNNEL_PORT < /dev/tty
    else
        FUNNEL_PORT="$1"
    fi

    echo "🌍 Enabling Funnel on port $FUNNEL_PORT..."
    sudo tailscale funnel "$FUNNEL_PORT"
    echo "✅ Funnel active on port $FUNNEL_PORT"
    echo "👉 Run 'tailscale funnel status' to check your public URL."
}

install_nginx() {
    echo "⬇️ Installing Nginx..."
    sudo apt update
    sudo apt install nginx -y
    sleep 4;
    sudo nginx -version
    sudo systemctl enable nginx
    sudo service nginx restart
}

open_nginx() {
    echo "Opening Nginx..."
    sudo nano /etc/nginx/sites-available/default
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
echo "9) Install Nginx"
echo "10) Open Nginx"
echo "11) Install Tailscale"
echo "12) Setup Tailscale Funnel"
echo "13) Install MongoDB"
echo "14) Install PM2"
echo "15) Install Cockpit"
echo "16) Install Docker"
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
        9) install_nginx ;;
        10) open_nginx ;;
        11) install_tailscale ;;
        12) setup_tailscale_funnel ;;
        13) install_mongodb ;;
        14) install_pm2 ;;
        15) install_cockpit ;;
        16) install_docker ;;
        *) echo "❌ Invalid option: $choice" ;;
    esac
done

echo "✅ Setup complete!"