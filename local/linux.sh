#!/bin/bash
# Author   : github.com/trevor256
# Summary  : install and configure applications for linux desktop or server.
# Supported: Debian

    CLI_APPS="default-jdk default-jre nodejs npm transmission-cli tree rsync ripgrep fzf curl ffmpeg shellcheck \
              ufw fail2ban rkhunter lynis libpam-tmpdir needrestart nzbget ca-certificates curl gnupg nvim nginx"
    DESKTOP_APPS="krita inkscape blender kdenlive obs-studio audacity chromium nmap tshark maven gradle"
    NPM_APPS="nodemon bash-language-server"
    
_desktop() {
    echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
    apt update && apt install -y $CLI_APPS $DESKTOP_APPS && npm install -g $NPM_APPS
    wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb" &
    wget -O jetbrains-toolbox-2.1.0.18144.tar.gz https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.1.0.18144.tar.gz &
    wget -O steam.deb https://cdn.akamai.steamstatic.com/client/installer/steam.deb &
    wget -O 4kvideodownloaderplus_1.2.4-1_amd64.deb https://dl.4kdownload.com/app/4kvideodownloaderplus_1.2.4-1_amd64.deb?source=website &
    wget -O atlauncher.deb https://atlauncher.com/download/deb &
    wait
    tar -xzf jetbrains-toolbox-2.1.0.18144.tar.gz
    dpkg -i discord.deb steam.deb 4kvideodownloaderplus_1.2.4-1_amd64.deb atlauncher.deb
    su - trevor -c "discord; steam; 4kvideodownloaderplus; atlauncher; ./jetbrains-toolbox-2.1.0.18144/jetbrains-toolbox"
}

_server(){
    sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
    apt update && apt install -y $CLI_APPS
    #0 3 * * 5 /path/to/your/maintancescript.sh
    systemctl disable NetworkManager-wait-online.service #-6 seconds #bootsystemd-analyze blame
    grep -rl GRUB_TIMEOUT=5 /etc/default/grub | xargs sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' && update-grub2 #-10 seconds 

    jelly_dirs="/jelly/downloads /jelly/movies /jelly/shows /jelly/music /jelly/other /jelly/x /jelly/configs"
    storage_dirs="/storage"
    [ -d "/jelly" ] || mkdir /jelly
    [ -d "/storage" ] || mkdir /storage
    mkdir -p $jelly_dirs $storage_dirs
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

    apt -y install nvidia-cuda-toolkit nvidia-driver build-essential pkg-config checkinstall git libfaac-dev libgpac-dev ladspa-sdk-dev libunistring-dev \
    libbz2-dev libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev \
    libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev libxfixes-dev texi2html yasm zlib1g-dev build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev
    apt update
    mkdir -p ~/nvidia/ && cd ~/nvidia/
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    cd nv-codec-headers && make install
    cd ~/nvidia/
    git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
    cd ~/nvidia/ffmpeg/
    ./configure --pkg-config-flags="--static" --enable-nonfree --enable-gpl --enable-version3 \
    --enable-libmp3lame --enable-libvpx --enable-libopus \
    --enable-opencl --enable-libxcb \
    --enable-opengl --enable-nvenc --enable-vaapi \
    --enable-vdpau --enable-ffplay --enable-ffprobe \
    --enable-libxvid \
    --enable-libx264 --enable-libx265 --enable-openal \
    --enable-cuda-nvcc --enable-cuvid --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64
    make -j "$(nproc)"
    echo "export PATH=\$PATH:/root/nvidia/ffmpeg" >> ~/.bashrc
    source ~/.bashrc
    
systemctl start nginx
systemctl enable nginx
nano /etc/nginx/sites-available/jellyfin
printf "server {
    listen 80;
    server_name t256.net;

    location / {
        proxy_pass http://localhost:8096;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
"
ln -s /etc/nginx/sites-available/jellyfin /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx

apt install certbot python3-certbot-nginx
certbot --nginx -d t256.net
certbot renew --dry-run

#email/text notification
#gitlab
#nextcloud
#Qmue test remote pc
#Web server (custom)

    curl https://repo.jellyfin.org/install-debuntu.sh | bash

    sed -i 's/^ControlPort=.*/ControlPort=8081/' /path/to/nzbget.conf
    
    transmission-daemon
    service transmission-daemon stop
    transmission-daemon --download-dir "your-download-directory-path"
    sed -i 's/"rpc-port":.*/"rpc-port": 9091,/' /path/to/settings.json
    sudo service transmission-daemon start
    #transmission-remote -l

printf "
    version: "3.9"
name: media-stack
services:
  traefik:
    image: traefik:v2.5
    container_name: traefik
    command:
      - "--log.level=DEBUG"
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.myresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.myresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.myresolver.acme.email=YOUR_EMAIL"
      - "--certificatesresolvers.myresolver.acme.storage=acme.json"
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/acme.json"
    networks:
      - media-network
    restart: always
    
  radarr:
    container_name: radarr
    image: lscr.io/linuxserver/radarr:4.5.2
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    ports:
      - 7878:7878
    volumes:
      - /config:/storage
      - /jelly:/jelly
    restart: always
    networks:
      - media-network
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.radarr.rule=Host(`radarr.yourdomain.com`)"
      - "traefik.http.routers.radarr.entrypoints=websecure"
      - "traefik.http.routers.radarr.tls.certresolver=myresolver"

  sonarr:
    image: linuxserver/sonarr:4.0.0-develop
    container_name: sonarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /config:/storage
      - /jelly:/jelly
    ports:
      - 8989:8989
    restart: always
    networks:
      - media-network

  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /config:/storage
    ports:
      - 9696:9696
    restart: always
    networks:
      - media-network

  requestrr:
    image: lscr.io/linuxserver/requestrr:latest
    container_name: requestrr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - /config:/storage
    ports:
      - 4545:4545
    restart: always
    networks:
      - media-network

networks:
  media-network:
    driver: bridge 
    "> /etc/systemd/system/minecraft.service 

   
    MOD_URL="https://cdn.modrinth.com/data/gvQqBUqZ/versions/2KMrj5c1/lithium-fabric-mc1.20-0.11.2.jar https://cdn.modrinth.com/data/P7dR8mSH/versions/n2c5lxAo/fabric-api-0.83.0%2B1.20.jar"
    mkdir -p /minecraft /minecraft/mods
    wget -O /minecraft/image.jpg https://pbs.twimg.com/media/E17dVsuVEAIpea1.jpg #scale=64:64" server-icon.png 
    wget -O  /minecraft/fabric.jar https://meta.fabricmc.net/v2/versions/loader/1.20.2/0.14.24/0.11.2/server/jar 
    wget -O /minecraft/mods $MOD_URL 
    echo 'eula=true' >> /minecraft/eula.txt 
    echo "java -Xmx4G -jar fabric.jar nogui" > /minecraft/run.sh 
    printf "[Unit]
    Description=run.sh on startup
    Wants=network.target
    After=network.target
    
    [Service]
    Nice=5
    KillMode=control-group
    SuccessExitStatus=0 1
    ReadWriteDirectories=/minecraft
    WorkingDirectory=/minecraft
    ExecStart=/minecraft/run.sh
    
    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/minecraft.service 
    systemctl enable minecraft.service
    systemctl start minecraft.service
}

_vpn() {
        sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
        nordvpn whitelist add subnet 192.168.1.0/24
        nordvpn login --token
        nordvpn connect
}

_git() {
        read -r -p "Enter Git user.name: " git_name
        read -r -p "Enter Git user.email: " git_email
        git config --global user.name "$git_name"
        git config --global user.email "$git_email"
        read -r -p "cache git credentials? (yes/no): " git_cache
        if [[ $git_cache == "yes" ]]; then
            git config --global credential.helper 'cache --timeout=259200' # 3days
        fi
        git config --global color.ui true
        git config --global help.autocorrect 1
}

_docker() {
        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/debian/gpg |  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
        "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
        "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update
        apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
}

_aws_gcloud() {
        # aws configure
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        aws configure set default.region us-east-1
        aws configure set default.output json
        #aws configure set aws_access_key_id $(< path_to_file_containing_access_key)
        #aws configure set aws_secret_access_key $(< path_to_file_containing_secret_key)
        aws configure
        # gcloud init
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        apt update && apt install -y google-cloud-sdk
        #gcloud auth activate-service-account --key-file=[PATH_TO_KEY_FILE]
        #gcloud config set project [YOUR_PROJECT_ID]
        #gcloud config set compute/zone [YOUR_COMPUTE_ZONE]
        gcloud init
}
_neovim() {
        mkdir -p ~/.config/nvim
        echo "set number" > ~/.config/nvim/init.vim
        echo "syntax on" >> ~/.config/nvim/init.vim
        curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        echo "call plug#begin('~/.local/share/nvim/plugged')" >> ~/.config/nvim/init.vim
        echo "Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }" >> ~/.config/nvim/init.vim
        echo "Plug 'junegunn/goyo.vim'" >> ~/.config/nvim/init.vim
        echo "call plug#end()" >> ~/.config/nvim/init.vim
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
        lynis
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
    echo "debian_desktop(dd), debian_server(ds" #,debian_cloud_server(dcs), custom(c)"
    read -r -p "what kind of computer set up? " choice

    case $choice in
        debian_desktop|dd)
                if uname -a | grep "Debian"; then
                   time _vpn
                   time _git
                   time _docker
                   time _aws_gcloud
                   time _neovim
                   time _desktop
                    echo "done"
                else echo "not Debian" exit 1
                fi
            ;;
        debian_server|ds)
               if uname -a | grep "Debian"; then
                    time _vpn
                    time _git
                    time _docker
                    time _neovim
                    time _server
                    echo "done"
                else echo "not Debian" exit 1
                fi
             ;;
    esac
}
main
