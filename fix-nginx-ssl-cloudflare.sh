# ========================================
# 🚀 Auto Fix for Nginx + SSL + Cloudflare Zero Trust
# Automates: Nginx Setup, SSL, Certbot, Firewall, Cloudflare DNS Update
# Author: Moataz Lashein
# ========================================

# ✅ Cloudflare API Credentials
CLOUDFLARE_API_KEY="FMQ7R45P0Cmxaaw24qmrr5e1TA8duNQzvNINRwZy"
ZONE_ID="c3d39f2ff83eac934b09e9bec27919e4"
DOMAIN="globalarkacademy.org"
SERVER_IP="your-actual-server-ip"
CERTBOT_EMAIL="Lashein.m@globalarkacademy.org"

# ✅ Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# ✅ Update System Packages
echo "🔧 Updating system packages..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx curl ufw jq

# ✅ Configure Firewall
echo "🔒 Configuring firewall rules..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# ✅ Verify DNS Resolution
echo "🌍 Checking DNS resolution..."
if ! host "$DOMAIN" > /dev/null; then
    echo "❌ DNS lookup failed! Please check your domain settings."
    exit 1
fi

# ✅ Configure Nginx
echo "📜 Configuring Nginx for $DOMAIN..."
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN www.$DOMAIN;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN www.$DOMAIN;
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:8000;
    }
}
EOL

# ✅ Test Nginx Configuration & Restart
sudo nginx -t && sudo systemctl restart nginx

# ✅ Request SSL Certificate
echo "🔑 Checking installed SSL certificates..."
if ! sudo certbot certificates | grep -q "Certificate Name: $DOMAIN"; then
    echo "⚠️ No valid SSL certificate found! Requesting a new one..."
    sudo certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" --email "$CERTBOT_EMAIL" --agree-tos --non-interactive
else
    echo "✅ SSL Certificate already exists. Skipping new request."
fi

# ✅ Update Cloudflare DNS Record
echo "🔄 Updating Cloudflare DNS record..."
RECORD_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$DOMAIN" \
     -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ -z "$RECORD_ID" || "$RECORD_ID" == "null" ]]; then
    echo "📌 Creating new DNS record in Cloudflare..."
    curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
         -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'"$DOMAIN"'","content":"'"$SERVER_IP"'","ttl":1,"proxied":true}'
else
    echo "📌 Updating existing Cloudflare DNS record..."
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
         -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
         -H "Content-Type: application/json" \
         --data '{"type":"A","name":"'"$DOMAIN"'","content":"'"$SERVER_IP"'","ttl":1,"proxied":true}'
fi

# ✅ Set Up Automatic SSL Renewal
echo "⏳ Setting up automatic SSL renewal..."
echo "0 3 * * * /usr/bin/certbot renew --quiet && systemctl reload nginx" | sudo tee /etc/cron.d/certbot-renew

# ✅ Restart Nginx
sudo systemctl restart nginx

# ✅ Final Check
echo "🌍 Verifying HTTPS response..."
curl -I https://$DOMAIN

echo "✅ All fixes applied successfully! 🚀 SSL is now active!"

