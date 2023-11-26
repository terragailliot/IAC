#!/bin/bash
# Author   : github.com/trevor256
# Summary  : install and configure applications for linux desktop or server.
# Supported: Debian

        NORD_TOKEN=""
          GIT_NAME="trevor256"
         GIT_EMAIL="256trevor@gmail.com"
           AWS_KEY=""
       AWS_SEC_KEY=""


          CLI_APPS="default-jdk default-jre nodejs npm transmission-cli transmission-common transmission-daemon tree rsync ripgrep fzf curl ffmpeg shellcheck unzip unrar \
                    ufw fail2ban rkhunter lynis libpam-tmpdir needrestart nzbget ca-certificates curl gnupg neovim nginx certbot \
                    python3-certbot-nginx"
          NPM_APPS="nodemon bash-language-server"
         DESK_APPS="krita inkscape blender kdenlive obs-studio audacity chromium nmap tshark maven gradle"
  SERVER_MEDIA_DIR="/jelly/downloads /jelly/nzbget /jelly/movies /jelly/shows /jelly/music /jelly/other /jelly/x /jelly/configs"
SERVER_STORAGE_DIR="/storage"
      NZB_MAIN_DIR1="/jelly/nzbget"
          NZB_HOST1="news.newshosting.com"
      NZB_USERNAME1=""
      NZB_PASSWORD1=""

_desktop() {
    cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
    apt update && apt upgrade
    apt install -y $CLI_APPS
    apt install -g $NPM_APPS
    apt install -y $DESK_APPS &
    wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb" &
    wget -O jetbrains-toolbox-2.1.0.18144.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.1.0.18144.tar.gz &
    wget -O steam.deb https://cdn.akamai.steamstatic.com/client/installer/steam.deb &
    wget -O 4kvideodownloaderplus_1.2.4-1_amd64.deb https://dl.4kdownload.com/app/4kvideodownloaderplus_1.2.4-1_amd64.deb?source=website &
    wget -O atlauncher.deb https://atlauncher.com/download/deb &
    wait
    tar -xzf jetbrains-toolbox-2.1.0.18144.tar.gz
    dpkg -i discord.deb steam.deb 4kvideodownloaderplus_1.2.4-1_amd64.deb atlauncher.deb
}

_server() {
    cp /etc/apt/sources.list /etc/apt/sources.list.backup
    sed -i '/^deb / s/$/ contrib non-free/' /etc/apt/sources.list
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    apt update && apt upgrade
    apt install -y $CLI_APPS

#DRIVE
    mkdir -p /jelly /storage
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
    add_to_fstab "9067c3d0-babc-4ffa-b8b9-4212a4fe4cea" "/jelly" "ext4" "defaults" "0" "0"
    add_to_fstab "16cc2161-d654-4cf4-a954-a7d61892d08c" "/storage" "ext4" "defaults" "0" "0"
    systemctl daemon-reload && mount --all
    mkdir -p $SERVER_MEDIA_DIR

#FFMPEG GPU COMPILE
    echo -e "blacklist nouveau\noptions nouveau modeset=0" | tee /etc/modprobe.d/blacklist-nouveau.conf
    update-initramfs -u
    apt -y install nvidia-cuda-toolkit nvidia-driver build-essential pkg-config checkinstall libfaac-dev ladspa-sdk-dev libunistring-dev libbz2-dev libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev libxfixes-dev texi2html yasm zlib1g-dev build-essential yasm cmake libtool libc6 libc6-dev libnuma1 libnuma-dev
    mkdir -p ~/nvidia/
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git ~/nvidia/nv-codec-headers
    make -C ~/nvidia/nv-codec-headers install
    git clone https://git.ffmpeg.org/ffmpeg.git ~/nvidia/ffmpeg
      ~/nvidia/ffmpeg/configure --pkg-config-flags="--static" --enable-nonfree --enable-gpl --enable-version3 \
      --enable-libmp3lame --enable-libvpx --enable-libopus \
      --enable-opencl --enable-libxcb \
      --enable-opengl --enable-nvenc --enable-vaapi \
      --enable-vdpau --enable-ffplay --enable-ffprobe \
      --enable-libxvid \
      --enable-libx264 --enable-libx265 --enable-openal \
      --enable-cuda-nvcc --enable-cuvid --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64
    make -j "$(nproc)" #might have to run this after a reboot
    echo "export PATH=\$PATH:/home/trevor/nvidia/ffmpeg" >> ~/.bashrc
    source ~/.bashrc
}

_vpn() {
        sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
        nordvpn whitelist add subnet 192.168.1.0/24
        nordvpn login --token $NORD_TOKEN
        nordvpn set autoconnect on
        nordvpn connect
}

_jelly() {
    curl https://repo.jellyfin.org/install-debuntu.sh | bash
}

_downloaders() {
    sed -i "s|^MainDir=.*|MainDir=$NZB_MAIN_DIR1|" /etc/nzbget.conf
    sed -i "s|^Server1.Name=.*|Server1.Name=newshosting|" /etc/nzbget.conf
    sed -i "s|^Server1.Host=.*|Server1.Host=$NZB_HOST1|" /etc/nzbget.conf
    sed -i "s|^Server1.Username=.*|Server1.Username=$NZB_USERNAME1|" /etc/nzbget.conf
    sed -i "s|^Server1.Password=.*|Server1.Password=$NZB_PASSWORD1|" /etc/nzbget.conf
    sed -i "s|^Server1.Encryption=.*|Server1.Encryption=yes|" /etc/nzbget.conf
    sed -i "s|^Server1.Port=.*|Server1.Port=563|" /etc/nzbget.conf
    sed -i "s|^ControlIP=.*|ControlIP=0.0.0.0|" /etc/nzbget.conf
    nzbget -D

    systemctl stop transmission-daemon
    sed -i 's|"download-queue-size":.*|"download-queue-size": 10,|' /var/lib/transmission-daemon/info/settings.json
    sed -i 's|"download-dir":.*|"download-dir": "/jelly/downloads",|' /var/lib/transmission-daemon/info/settings.json
    sed -i 's|"rpc-authentication-required":.*|"rpc-authentication-required": false,|' /var/lib/transmission-daemon/info/settings.json
    sed -i 's|"rpc-whitelist-enabled":.*|"rpc-whitelist-enabled": false,|' /var/lib/transmission-daemon/info/settings.json
    systemctl enable --now transmission-daemon
}

_nginx() {
  # nginx
    systemctl enable --now nginx
        printf "server {
            listen 80;
            server_name t256.net;

            location / {
                proxy_pass http://localhost:8096;
                proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto \$scheme;
            }
        }
        " | sudo tee /etc/nginx/sites-available/jellyfin > /dev/null
    ln -s /etc/nginx/sites-available/jellyfin /etc/nginx/sites-enabled/
    nginx -t
    systemctl reload nginx
    certbot --nginx -d t256.net
    certbot renew --dry-run

#Web server (custom)
}

_docker() {
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt update
        apt -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
}

_compose() {
sh -c "printf '
version: '3.9'
name: media-stack
services:
  radarr:
    container_name: radarr
    image: lscr.io/linuxserver/radarr:4.5.2
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /jelly/movies:/movies
      - /jelly/configs/radarr:/config
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
      - /jelly/shows:/tv
      - /jelly/configs/sonarr:/config
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
      - /jelly/configs/prowlarr:/config
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
      - /jelly/configs/requestrr:/config
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
      - /jelly/x:/adult
      - /jelly/configs/whisparr:/config
    ports:
      - "6969:6969"
    restart: always

  lidarr:
    image: ghcr.io/hotio/lidarr
    container_name: lidarr
    environment:
      - PUID
