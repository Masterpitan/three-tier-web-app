#!/bin/bash
# =====================================================
# DevOps Intern Stage 1 Task: Automated Deployment Script
# Author: <Your Name>
# =====================================================

LOG_FILE="deploy_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Utility Functions ---
log() { echo -e "\033[1;34m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
error_exit() { echo -e "\033[1;31m[ERROR]\033[0m $1"; exit 1; }

trap 'error_exit "Unexpected error occurred. Check $LOG_FILE for details."' ERR

# --- Step 1: Collect Parameters ---
log "=== Collecting Deployment Parameters ==="

read -p "Enter GitHub repository URL (HTTPS or SSH): " REPO_URL
read -p "Enter Personal Access Token (leave blank if public or using SSH): " PAT
read -p "Enter branch name [default: main]: " BRANCH
BRANCH=${BRANCH:-main}

read -p "Enter Remote Server Username (e.g., ubuntu): " SSH_USER
read -p "Enter Remote Server IP Address: " SERVER_IP
read -p "Enter path to your SSH private key (e.g., ~/.ssh/id_rsa): " SSH_KEY
read -p "Enter Application Port (container internal port): " APP_PORT

APP_DIR="/home/$SSH_USER/app"
APP_NAME="my_docker_app"

# --- Step 2: Validate SSH Connection ---
log "=== Validating SSH connection to $SERVER_IP ==="
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$SSH_USER@$SERVER_IP" "echo 'SSH connection successful.'" || error_exit "SSH connection failed!"

# --- Step 3: Prepare Remote Environment ---
log "=== Preparing Remote Server Environment ==="
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
  set -e
  sudo apt update -y
  sudo apt install -y git docker.io docker-compose nginx
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker $USER || true
EOF

# --- Step 4: Clone or Update Repository ---
log "=== Cloning or Updating Repository on Remote Server ==="

if [ -n "$PAT" ]; then
  AUTH_REPO_URL=$(echo "$REPO_URL" | sed "s#https://#https://$PAT@#")
else
  AUTH_REPO_URL="$REPO_URL"
fi

ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
  set -e
  if [ -d "$APP_DIR/.git" ]; then
    echo "Repository exists. Pulling latest changes..."
    cd "$APP_DIR"
    git pull origin "$BRANCH"
  else
    echo "Cloning repository..."
    git clone -b "$BRANCH" "$AUTH_REPO_URL" "$APP_DIR"
  fi
EOF

# --- Step 5: Deploy Dockerized Application ---
log "=== Deploying Dockerized Application ==="
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
  set -e
  cd "$APP_DIR"

  if [ -f docker-compose.yml ]; then
    echo "docker-compose.yml found. Using Docker Compose..."
    sudo docker-compose down || true
    sudo docker-compose up -d --build
  elif [ -f Dockerfile ]; then
    echo "Dockerfile found. Building manually..."
    sudo docker build -t $APP_NAME .
    sudo docker stop $APP_NAME || true
    sudo docker rm $APP_NAME || true
    sudo docker run -d -p 80:$APP_PORT --name $APP_NAME $APP_NAME
  else
    echo "No Dockerfile or docker-compose.yml found!"
    exit 1
  fi
EOF

# --- Step 6: Configure Nginx Reverse Proxy ---
log "=== Configuring Nginx Reverse Proxy ==="
NGINX_CONF="/etc/nginx/sites-available/$APP_NAME"
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
  set -e
  sudo bash -c 'cat > $NGINX_CONF' <<NGINXCONF
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:$APP_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
NGINXCONF
  sudo ln -sf $NGINX_CONF /etc/nginx/sites-enabled/
  sudo nginx -t
  sudo systemctl reload nginx
EOF

# --- Step 7: Validate Deployment ---
log "=== Validating Deployment ==="
ssh -i "$SSH_KEY" "$SSH_USER@$SERVER_IP" bash <<EOF
  set -e
  echo "Checking Docker container status..."
  sudo docker ps | grep $APP_NAME || { echo "Container not running!"; exit 1; }

  echo "Testing local curl request..."
  curl -I http://127.0.0.1 || { echo "App not responding locally"; exit 1; }
EOF

# --- Step 8: Done ---
PUBLIC_IP=$(curl -s http://checkip.amazonaws.com)
log "✅ Deployment successful!"
log "Access your app at: http://$PUBLIC_IP"

exit 0
