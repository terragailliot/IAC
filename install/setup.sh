#!/bin/bash
# Author   : trevor
# Summary  : install and configure linux.

    SOFTWARE_LANGS="default-jdk default-jre maven gradle nodejs npm python3 python3-pip python3-venv"
          
          CLI_APPS="rsync fail2ban ripgrep ffmpeg"

         APT="krita inkscape obs-studio audacity chromium discord zoom-client steam beekeeper-studio"

    apt update && apt -y upgrade
    apt install -y $SOFTWARE_LANGS $CLI_APPS
    wget -O 4kvideodownloaderplus.deb https://www.4kdownload.com/thanks-for-downloading?source=videodownloaderplus
    dpkg -i 4kvideodownloaderplus.deb

    docker-compose -f mediaserver.yaml up -d
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw reload
    sudo certbot --nginx -d terraaa.com -d www.terraaa.com

 _nvim(){   

# Install Neovim
sudo apt install neovim

# Install Vim-Plug for plugin management
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# Create Neovim configuration directory if it doesn't exist
mkdir -p ~/.config/nvim

# Create Neovim configuration file if it doesn't exist
touch ~/.config/nvim/init.vim

# Configure Neovim with plugins and settings
cat << EOF >> ~/.config/nvim/init.vim
call plug#begin('~/.config/nvim/plugged')
" NERDTree plugin
Plug 'preservim/nerdtree'
" Vim-Fugitive plugin for Git integration
Plug 'tpope/vim-fugitive'
call plug#end()

" Enable mouse support
set mouse=a
EOF

# Install plugins using Vim-Plug
nvim -c 'PlugInstall' -c 'qa!'

}

_drives() {  
    SERVER_SUB_DIR="/drives/vids/movies /drives/vids/shows /drives/vids/x /drives/services/downloads /drives/services/nzbget /drives/services/music /drives/services/configs"
    mkdir -p /drives 
    mkdir -p /drives/vids /drives/services /drives/storage
    add_to_fstab() {
      local uuid=$1
      local mount_point=$2
      local fs_type=$3
      local options=$4
      local dump_freq=$5
      local pass_num=$6
      if ! grep -qs "$uuid" /etc/fstab; then
        echo "UUID=$uuid $mount_point $fs_type $options $dump_freq $pass_num" >> /etc/fstab
      else
        echo "UUID entry for $uuid already exists in /etc/fstab."
      fi
    }
    add_to_fstab "9067c3d0-babc-4ffa-b8b9-4212a4fe4cea" "/drives/services" "ext4" "defaults" "0" "0"
    add_to_fstab "16cc2161-d654-4cf4-a954-a7d61892d08c" "/drives/storage" "ext4" "defaults" "0" "0"
    add_to_fstab "a83b1184-484c-4086-96cd-80fe60b3cba0" "/drives/vids" "ext4" "defaults" "0" "0"
    systemctl daemon-reload && mount --all
    mkdir -p $SERVER_SUB_DIR
}

_samba() {
    cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
    printf '
    [global]
      workgroup = WORKGROUP
      security = user
      map to guest = Bad User
      guest account = nobody
      server string = Samba Server %%v
      netbios name = debian
      dns proxy = no
      log file = /var/log/samba/log.%%m
      max log size = 1000
      syslog = 0
      panic action = /usr/share/samba/panic-action %%d
      server role = standalone server
      passdb backend = tdbsam
      obey pam restrictions = yes
      unix password sync = yes
      passwd program = /usr/bin/passwd %%u
      passwd chat = *Enter\\\\snew\\\\s*\\\\spassword:* %%n\\\\n *Retype\\\\snew\\\\s*\\\\spassword:* %%n\\\\n *password\\\\supdated\\\\ssuccessfully* .
      pam password change = yes
      load printers = no
      printcap name = /dev/null
      disable spoolss = yes

    [Storage]
      path = /drives/storage
      browseable = yes
      read only = no
      guest ok = yes
      create mask = 0775
      directory mask = 0775
    ' | tee /etc/samba/smb.conf
      chmod 2775 /drives/storage
      chown nobody:nogroup /drives/storage
      sudo service smbd restart
}

_nginx() {
    apt install -y nginx certbot python3-certbot-nginx
    systemctl enable --now nginx
        printf "
server {
    listen 80;
    server_name t256.net;
    return 301 https://\$host\$request_uri;
}

# HTTPS server block for the main site and Jellyfin
server {
    #listen 443 ssl http2;
    server_name t256.net;

    # SSL configuration # comment un comment
    #ssl_certificate /etc/letsencrypt/live/t256.net/fullchain.pem;
    #ssl_certificate_key /etc/letsencrypt/live/t256.net/privkey.pem;
    #include /etc/letsencrypt/options-ssl-nginx.conf;
    #ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    # Root location for the website
    location / {
        root /var/www/html;
        index index.html index.htm;
        try_files \$uri \$uri/ =404;
    }

    location /jelly {
        # Note the trailing slash after the port number is very important here!
        proxy_pass http://192.168.1.3:8096;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}" | tee /etc/nginx/sites-available/jellyfin >> /dev/null
    ln -s /etc/nginx/sites-available/jellyfin /etc/nginx/sites-enabled/
    rm /etc/nginx/sites-available/default
    rm /etc/nginx/sites-enabled/default
    nginx -t
    systemctl reload nginx
    certbot --nginx -d t256.net
    certbot renew --dry-run
}

_downloaders() {
    sed -i "s|^MainDir=.*|MainDir=$NZB_MAIN_DIR1|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Name=.*|Server1.Name=newshosting|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Host=.*|Server1.Host=$NZB_HOST1|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Username=.*|Server1.Username=$NZB_USERNAME1|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Password=.*|Server1.Password=$NZB_PASSWORD1|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Encryption=.*|Server1.Encryption=yes|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^Server1.Port=.*|Server1.Port=563|" /drives/services/configs/nzbget/nzbget.conf
    sed -i "s|^ControlIP=.*|ControlIP=0.0.0.0|" /drives/services/configs/nzbget/nzbget.conf

    sed -i 's|"download-queue-size":.*|"download-queue-size": 10,|' /drives/services/configs/transmission/settings.json
    sed -i 's|"download-dir":.*|"download-dir": "/drives/services/downloads/transmission",|' /drives/services/configs/transmission/settings.json
    sed -i 's|"rpc-authentication-required":.*|"rpc-authentication-required": false,|' /drives/services/configs/transmission/settings.json
    sed -i 's|"rpc-whitelist-enabled":.*|"rpc-whitelist-enabled": false,|' /drives/services/configs/transmission/settings.json
}

_cloud() {
       AWS_KEY=""
       AWS_SEC_KEY=""
        # aws configure
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        aws configure set default.region us-east-1
        aws configure set default.output json
        aws configure set aws_access_key_id $AWS_KEY
        aws configure set aws_secret_access_key $AWS_SEC_KEY

        curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-459.0.0-linux-x86_64.tar.gz
        tar -xf google-cloud-cli-459.0.0-linux-x86_64.tar.gz
        ./google-cloud-sdk/install.sh
        gcloud init
}


main() {
    echo "mx_desktop(mx), debian_desktop(dd), debian_server(ds), cloud9(c9)"
    read -r -p "select config ??: " choice

    case $choice in
        debian_desktop|dd)
                if uname -a | grep "Debian"; then
                  time _desktop
                  time _cloud
                  echo "done"
                else echo "not Debian" exit 1
                fi;;
        debian_server|ds)
               if uname -a | grep "Debian"; then
                  time _server
                  time _drives
                  time _samba
                  echo "done"
                else echo "not Debian" exit 1
                fi;;
        cloud9|c9)
               if uname -a | grep "aws"; then
                  time _cloud9
                  echo "done"
                else echo "not Debian" exit 1
                fi;;
    esac
}

main
