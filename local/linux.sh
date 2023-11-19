#!/bin/bash
# Author   : github.com/trevor256
# Summary  : install and configure applications for a desktop, server.
# Supported: Debian

    CLI_APPS="default-jdk default-jre maven gradle nodejs npm transmission-cli tree rsync \
              ufw fail2ban rkhunter lynis libpam-tmpdir apt-listbugs needrestart nzbget \
              ripgrep fzf curl ffmpeg nmap tshark shellcheck ca-certificates curl gnupg"

    GUI_APPS="krita inkscape blender kdenlive obs-studio audacity chromium"

    NPM_APPS="nodemon bash-language-server react jest"

_setup() {
    echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
    apt update && apt install -y $CLI_APPS
}
_desktop() {
    apt install -y $GUI_APPS && npm install -g $NPM_APPS
    wget -O discord.deb "https://discordapp.com/api/download?platform=linux&format=deb"
    dpkg -i discord.deb
    su - trevor -c "discord"

    wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.1.0.18144.tar.gz  -O jetbrains-toolbox-2.1.0.18144.tar.gz
    tar -xzf jetbrains-toolbox-2.1.0.18144.tar.gz
    ./jetbrains-toolbox-2.1.0.18144/jetbrains-toolbox

    wget https://cdn.akamai.steamstatic.com/client/installer/steam.deb -O steam.deb
    dpkg -i steam.deb
    su - trevor -c "steam"

    wget https://dl.4kdownload.com/app/4kvideodownloaderplus_1.2.4-1_amd64.deb?source=website -O 4kvideodownloaderplus_1.2.4-1_amd64.deb
    dpkg -i 4kvideodownloaderplus_1.2.4-1_amd64.deb
    su - trevor -c "4kvideodownloaderplus"

    wget https://atlauncher.com/download/deb -O atlauncher.deb
    dpkg -i atlauncher.deb
    su - trevor -c "atlauncher"
}

_server(){
    #MAKE CRON JOBS FOR BACK UP AND COMPRESSION
    # check boot times with: systemd-analyze blame set grub timeout to 0 saves 10sec on boot
    systemctl disable NetworkManager-wait-online.service # saves 6 seconds on boot
    grep -rl GRUB_TIMEOUT=5 /etc/default/grub | xargs sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' && update-grub2

    SSH_CONFIG_FILE="/etc/ssh/sshd_config"
    if grep -q "^PermitRootLogin" $SSH_CONFIG_FILE; then
        sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' $SSH_CONFIG_FILE
    else
        echo "PermitRootLogin no" >> $SSH_CONFIG_FILE
    fi

    [ -d "/jelly" ] || mkdir /jelly
    mkdir /jelly /storage
    mkdir /jelly/downloads /storage/config /jelly/movies /jelly/shows
    echo "UUID=9067c3d0-babc-4ffa-b8b9-4212a4fe4cea /jelly ext4 defaults 0 0" >> /etc/fstab
    echo "UUID=16cc2161-d654-4cf4-a954-a7d61892d08c /storage ext4 defaults 0 0" >> /etc/fstab
    systemctl daemon-reload && mount --all

    apt install -y nvidia-cuda-toolkit nvidia-driver nvidia-container-toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
    && curl -s -L https://nvidia.github.io/libnvidia-container/debian11/libnvidia-container.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

    apt update
    nvidia-ctk runtime configure --runtime=docker
    systemctl restart docker

# Ensure the script is run as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Update and Install Dependencies
apt update
apt -y install build-essential pkg-config checkinstall git libfaac-dev libgpac-dev ladspa-sdk-dev libunistring-dev libbz2-dev libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev libxfixes-dev texi2html yasm zlib1g-dev build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev

mkdir -p ~/nvidia/ && cd ~/nvidia/
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers && make install
cd ~/nvidia/
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
cd ~/nvidia/ffmpeg/

# Configure FFmpeg with NVIDIA Support
./configure --pkg-config-flags="--static" --enable-nonfree --enable-gpl --enable-version3 \
--enable-libmp3lame --enable-libvpx --enable-libopus \
--enable-opencl --enable-libxcb \
--enable-opengl --enable-nvenc --enable-vaapi \
--enable-vdpau --enable-ffplay --enable-ffprobe \
--enable-libxvid \
--enable-libx264 --enable-libx265 --enable-openal \
--enable-cuda-nvcc --enable-cuvid --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64

# Compile FFmpeg
make -j "$(nproc)"

# Final Steps and Verification
if [ -f "ffmpeg" ]; then
    echo "FFmpeg compilation successful. Installing..."
    checkinstall --pkgname=ffmpeg-nvidia --pkgversion="1:$(date +%Y%m%d%H%M)-git" --backup=no \
    --deldoc=yes --fstrans=no --default
    echo "FFmpeg with NVIDIA support installed."
else
    echo "FFmpeg compilation failed."
    exit 1
fi

# Add FFmpeg to Path
echo "export PATH=\$PATH:/root/nvidia/ffmpeg" >> ~/.bashrc
source ~/.bashrc

    #sudo ufw enable
    #config ufw
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

_docker(){
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

    usermod -aG docker "$(whoami)"
}

_aws_gcloud() {
   if ! command -v aws &> /dev/null; then
        echo "Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf awscliv2.zip aws  # Cleanup
        echo "AWS CLI installed."
        aws configure set default.region us-east-1
        aws configure set default.output json
        aws configure
    else
        echo "AWS CLI is already installed."
    fi

    if ! command -v gcloud &> /dev/null; then
        echo "Installing Google Cloud SDK..."
        sudo apt-get install -y apt-transport-https ca-certificates gnupg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
        sudo apt-get update
        sudo apt-get install -y google-cloud-sdk
        echo "Google Cloud SDK installed."
        gcloud init
    else
        echo "Google Cloud SDK is already installed."
    fi

}

_security(){
    rkhunter --propupd
    rkhunter -c --enable all --disable none

    lynis
}
main() {
    echo "debian_desktop (dd), debian_server (ds), debian_cloud_server (dcs), cloud9 (c9), custom (c)"
    read -r -p "what kind of linux computer would you like to set up? " action

    case $action in
        debian_desktop|dd)
                if uname -a | grep "Debian"; then
                   time _setup
                   time _desktop
                   time _git
                   time _docker
                   time _aws_gcloud
# rsync or backup and neovim setup ffmpeg compression
                    echo "done"

                else
                    echo "Debian not found."
                    exit 1
                fi

            ;;
        debian_server|ds)
               if uname -a | grep "Debian"; then
                    time _setup
                    time _server
                    time _git
                    time _docker
                    echo "done"

                else
                    echo "Debian not found."
                    exit 1
                fi
             ;;
    esac
}
main
