#!/bin/bash
# Author   : github.com/trevor256
# Summary  : install and configure applications for linux desktop or server.
# Supported: Debian

        NORD_TOKEN=""
          GIT_NAME=""
         GIT_EMAIL=""
           AWS_KEY=""
       AWS_SEC_KEY=""


          CLI_APPS="default-jdk default-jre nodejs npm transmission-cli transmission-common transmission-daemon tree rsync \
                    ripgrep fzf curl ffmpeg shellcheck unzip unrar htop samba samba-common-bin \
                    ufw fail2ban rkhunter lynis libpam-tmpdir needrestart nzbget ca-certificates curl gnupg neovim nginx certbot \
                    python3-certbot-nginx"
          NPM_APPS="nodemon bash-language-server"
         DESK_APPS="krita inkscape blender kdenlive obs-studio audacity chromium nmap tshark maven gradle"
  SERVER_MEDIA_DIR="/jelly/downloads /jelly/nzbget /jelly/movies /jelly/shows /jelly/music /jelly/other /jelly/x /jelly/configs"
SERVER_STORAGE_DIR="/storage"
      NZB_MAIN_DIR1="/jelly/nzbget"
          NZB_HOST1="news.newsgroupdirect.com"
      NZB_USERNAME1="etk385654366"
      NZB_PASSWORD1=""

_kbuntu() {

sudo apt update
wget https://repo.radeon.com/amdgpu-install/23.20.00.48/ubuntu/jammy/amdgpu-install_5.7.00.48.50700-1_all.deb
sudo apt install ./amdgpu-install_5.7.00.48.50700-1_all.deb
sudo amdgpu-install -y --usecase=graphics,rocm
sudo usermod -a -G render,video $LOGNAME


sudo dpkg -i amdgpu-install_5.7.50702-1_all.deb
amdgpu-install -y --accept-eula
sudo apt install -y linux-headers-$(uname -r)
sudo usermod -a -G video trevor
sudo usermod -a -G render trevor
}


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

#samba
  printf "
      [Storage]
    path = /storage
    browseable = yes
    read only = no
    writable = yes
    guest ok = yes
    create mask = 0775
    directory mask = 0775
  " | tee /etc/samba/smb.conf >> /dev/null
  chmod 2775 /storage

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
        nordvpn login --token $NORD_TOKEN
        nordvpn whitelist add subnet 192.168.1.0/24
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
    systemctl enable --now nginx
        printf "
server {
    listen 80;
    server_name t256.net;
    return 301 https://\$host\$request_uri;
}

# HTTPS server block for the main site and Jellyfin
server {
    listen 443 ssl http2;
    server_name t256.net;

    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/t256.net/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/t256.net/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - /jelly/configs/lidarr:/config
      - /jelly/music:/data
    ports:
      - "8686:8686"
    restart: always

networks:
  media-network:
    driver: bridge
' > /docker-compose.yml"
docker-compose -f /docker-compose.yml up -d
}

_minecraft_server() {
    mkdir -p /jelly/minecraft /jelly/minecraft/mods
    wget -O /jelly/minecraft/server-icon.png https://freepngimg.com/save/9220-anime-png-images/64x64 #scale=64:64" server-icon.png
    wget -O /jelly/minecraft/server.jar https://piston-data.mojang.com/v1/objects/5b868151bd02b41319f54c8d4061b8cae84e665c/server.jar
    echo 'eula=true' >> /jelly/minecraft/eula.txt
    echo '#!/bin/bash
    java -Xms1024M -Xmx4G -jar /jelly/minecraft/server.jar nogui' > /jelly/minecraft/run.sh
    chmod +x /jelly/minecraft/run.sh
    printf "[Unit]
    Description=run.sh on startup
    Requires=network.target
    After=network.target

    [Service]
    User=minecraft
    Group=minecraft
    Nice=5
    KillMode=control-group
    SuccessExitStatus=0 1
    ReadWriteDirectories=/jelly/minecraft
    WorkingDirectory=/jelly/minecraft
    ExecStart=/jelly/minecraft/run.sh
    Restart=on-failure
    RestartSec=5s

    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/minecraft.service
    systemctl daemon-reload
    groupadd minecraft
    useradd -m -g minecraft minecraft
    chown -R minecraft:minecraft /jelly/minecraft/
    chmod -R u+rwX,go+rX /jelly/minecraft/

    systemctl enable --now minecraft.service
    bash /jelly/minecraft/run.sh
}

_git() {
        git config --global user.name "$GIT_NAME"
        git config --global user.email "$GIT_EMAIL"
        git config --global credential.helper 'cache --timeout=5259200'
        git config --global color.ui true
        git config --global help.autocorrect 1
}

_aws_gcloud() {
        # aws configure
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        ./aws/install
        aws configure set default.region us-east-1
        aws configure set default.output json
        aws configure set aws_access_key_id $AWS_KEY
        aws configure set aws_secret_access_key $AWS_SEC_KEY
}

_neovim() {
        mkdir -p ~/.config/nvim
        sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
       https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

       printf '
        Set line numbering
set number

" Enable syntax highlighting
syntax on

" Set tabs to have 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab

" Enable mouse support
set mouse=a

" Set a theme, if you have one installed
" colorscheme gruvbox

" Set incremental search
set incsearch

" Show command in the bottom bar
set showcmd

" Highlight current line
set cursorline

" Enable line wrapping
set wrap

" Set clipboard to use system clipboard
set clipboard=unnamedplus


call plug#begin('~/.local/share/nvim/plugged')

" Add your plugins here. For example:
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'neoclide/coc.nvim', {'branch': 'release'}

call plug#end()' >> ~/.config/nvim/init.vim
        
}

_extra () {
        rsync -avz /path/to/source/directory/ username@192.168.1.3:/path/to/destination/directory/

        # Check if an argument is given (input file)
        if [ "$#" -ne 1 ]; then
            echo "Usage: $0 [Input File]"
            exit 1
        fi
        INPUT_FILE=$1
        OUTPUT_FILE="${INPUT_FILE%.*}.mp4"
        ffmpeg -i "$INPUT_FILE" -vcodec libx264 -crf 23 -preset medium "$OUTPUT_FILE"
        echo "Conversion complete: $OUTPUT_FILE"

}

_security(){
        rkhunter --propupd
        rkhunter -c --enable all --disable none
        lynis system audit
        lynis --pentest

        #ufw
}

_router() {
    apt install hostapd dnsmasq iptables-persistent
        /etc/network/interfaces
            iface eth1 inet static
            address 192.168.1.1
            netmask 255.255.255.0
        /etc/dnsmasq.conf
            interface=eth1
            dhcp-range=192.168.1.50,192.168.1.150,12h
        /etc/sysctl.conf
            net.ipv4.ip_forward=1
        sysctl -p
        iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
        netfilter-persistent save

        /etc/hostapd/hostapd.conf
        Enable and start hostapd service.
        Restart networking services or reboot the system.
        tc badwith control?
}

main() {
    echo "debian_desktop(dd), debian_server(ds"
    read -r -p "select config ??: " choice

    case $choice in
        debian_desktop|dd)
                if uname -a | grep "Debian"; then
                   time _desktop
                   time _vpn
                   time _git
                   time _docker
                   time _aws_gcloud
                   time _neovim
                    echo "done"
                else echo "not Debian" exit 1
                fi;;
        debian_server|ds)
               if uname -a | grep "Debian"; then
                   time _server
                   time _vpn
                   time _jelly
                   time _downloaders
                   time _nginx
                   time _docker
                   time _compose
                   time _minecraft_server
                    echo "done"
                else echo "not Debian" exit 1
                fi;;
    esac
}
main
#email/text notification
#gitlab
#nextcloud
