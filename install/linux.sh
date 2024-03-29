#!/bin/bash
# Author   : trevor
# Summary  : install and configure linux.

    SOFTWARE_LANGS="default-jdk default-jre maven gradle nodejs npm python3 python3-pip python3-venv"
          
          CLI_APPS="rsync curl fail2ban ufw ca-certificates gnupg ripgrep ffmpeg"

         SNAPS="krita inkscape obs-studio audacity chromium discord zoom-client steam beekeeper-studio"


_kubuntu(){
    apt update && apt -y upgrade
    apt install -y $SOFTWARE_LANGS $CLI_APPS
    snap install $SNAPS
    snap install blender --classic
    wget -O 4kvideodownloaderplus.deb https://www.4kdownload.com/thanks-for-downloading?source=videodownloaderplus
    dpkg -i 4kvideodownloaderplus.deb
   
}
_cloud9(){ 
    apt update && apt -y upgrade
    apt install -y $SOFTWARE_LANGS $CLI_APPS
}

_server() {
    #sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    #sed -i 's/GRUB_TIMEOUT=[0-9]*/GRUB_TIMEOUT=0/' /etc/default/grub && update-grub
    apt update && apt -y upgrade
    apt install -y $CLI_APPS
}

 _nvim(){   
    apt install neovim
    mkdir -p ~/.config/nvim
    echo "set number" > ~/.config/nvim/init.vim
    echo "syntax on" >> ~/.config/nvim/init.vim
    echo "set mouse=a" >> ~/.config/nvim/init.vim
    curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "call plug#begin('~/.local/share/nvim/plugged')" >> ~/.config/nvim/init.vim
    echo "Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }" >> ~/.config/nvim/init.vim
    echo "Plug 'junegunn/goyo.vim'" >> ~/.config/nvim/init.vim
    echo "call plug#end()" >> ~/.config/nvim/init.vim
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
    apt install -y samba samba-common-bin 
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
      systemctl restart smbd
}

_jellyfin() {
    curl https://repo.jellyfin.org/install-debuntu.sh | bash
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

_docker() {
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y docker-ce docker-ce-cli containerd.io
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose | chmod +x /usr/local/bin/docker-compose

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


_compose() {
sh -c "printf '
version: '3.9'
services:
  radarr:
    container_name: radarr
    image: lscr.io/linuxserver/radarr:4.5.2
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/vids/movies:/movies
      - /drives/services/configs/radarr:/config
    ports:
      - 7878:7878
    restart: always

  sonarr:
    image: linuxserver/sonarr:4.0.0-develop
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/vids/shows:/tv
      - /drives/services/configs/sonarr:/config
    ports:
      - 8989:8989
    restart: always

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/services/configs/prowlarr:/config
    ports:
      - 9696:9696
    restart: always

  requestrr:
    image: lscr.io/linuxserver/requestrr:latest
    container_name: requestrr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/services/configs/requestrr:/config
    ports:
      - 4545:4545
    restart: always

  whisparr:
    image: hotio/whisparr
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/vids/x:/x
      - /drives/services/configs/whisparr:/config
    ports:
      - 6969:6969
    restart: always

  transmission:
    image: linuxserver/transmission
    container_name: transmission
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/services/configs/transmission:/config
      - /drives/services/downloads/transmission:/downloads
    ports:
      - 9091:9091
      - 51413:51413
      - 51413:51413/udp
    restart: always

  nzbget:
    image: linuxserver/nzbget
    container_name: nzbget
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /drives/services/configs/nzbget:/config
      - /drives/services/downloads/nzbget:/downloads
    ports:
      - 6789:6789
    restart: always

networks:
  media-network:
    driver: bridge

' > /docker-compose.yml"
docker-compose -f /docker-compose.yml up -d
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