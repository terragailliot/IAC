#!/bin/bash
# Author   : github.com/trevor256
# Summary  : install and configure applications for a desktop, server.
# Supported: Debian
#
# fgqargRGQARGAERGARGARGFARGFASRGARGARSGAERGQAEWRGWQERGWERGWE
#
    CLI_APPS="default-jdk default-jre nodejs npm transmission-cli tree rsync ripgrep fzf curl ffmpeg  shellcheck \
              ufw fail2ban rkhunter lynis libpam-tmpdir needrestart nzbget ca-certificates curl gnupg nvim"
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
    curl -OJ $ICON_URL #must be 64x64 server-icon.png
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

    apt install -y nvidia-cuda-toolkit nvidia-driver nvidia-container-toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/debian11/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    apt update
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker

    apt update
    apt -y install build-essential pkg-config checkinstall git libfaac-dev libgpac-dev ladspa-sdk-dev libunistring-dev libbz2-dev libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev libxfixes-dev texi2html yasm zlib1g-dev build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev
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
    
    MOD_URL="https://cdn.modrinth.com/data/gvQqBUqZ/versions/2KMrj5c1/lithium-fabric-mc1.20-0.11.2.jar https://cdn.modrinth.com/data/P7dR8mSH/versions/n2c5lxAo/fabric-api-0.83.0%2B1.20.jar"
    wget -O  fabric.jar https://meta.fabricmc.net/v2/versions/loader/1.20.2/0.14.24/0.11.2/server/jar &
    wget -O /mods $MOD_URL &
    echo 'eula=true' >> eula.txt 
    echo "java -Xmx4G -jar https://meta.fabricmc.net/v2/versions/loader/1.20.2/0.14.24/0.11.2/server/jar nogui" > run.sh 
    printf "[Unit]
    Description=run.sh on startup
    Wants=network.target
    After=network.target
    
    [Service]
    Nice=5
    KillMode=control-group
    SuccessExitStatus=0 1
    ReadWriteDirectories=/home/admin/
    WorkingDirectory=/home/admin/
    ExecStart=/home/admin/run.sh
    
    [Install]
    WantedBy=multi-user.target" > /etc/systemd/system/minecraft.service 
    wait
    systemctl enable minecraft.service
    systemctl start minecraft.service
}

_vpn() {
        sh <(wget -qO - https://downloads.nordcdn.com/apps/linux/install.sh)
        nordvpn login
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
        aws configure set aws_access_key_id $(< path_to_file_containing_access_key)
        aws configure set aws_secret_access_key $(< path_to_file_containing_secret_key)
        # gcloud init
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        apt update && apt install -y google-cloud-sdk
        gcloud auth activate-service-account --key-file=[PATH_TO_KEY_FILE]
        gcloud config set project [YOUR_PROJECT_ID]
        gcloud config set compute/zone [YOUR_COMPUTE_ZONE]
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
