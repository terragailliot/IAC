#!/bin/bash

# Author: github.com/trevor256
# Summary: Check OS, install and configure applications.
# Supported: Debian

    CLI_APPS="default-jdk default-jre maven nodejs npm pip transmission-cli zsh \
              silversearcher-ag tmate fzf lynis curl ffmpeg neovim nmap tshark"
   
    APT_APPS="krita inkscape blender kdenlive obs-studio audacity flatpak chromium"

setup() {
    #set -e
    # check boot times with: systemd-analyze blame set grub timeout to 0 saves 10sec on boot
    # grep -rl GRUB_TIMEOUT=5 /etc/default/grub | xargs sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' && update-grub2
    # netselect-apt
    sudo apt update && sudo apt install -y $CLI_APPS
    sudo npm install -g nodemon
}

zsh() {
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
    sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    sed -i "/^plugins=/ s/)/ zsh-autosuggestions zsh-syntax-highlighting)/" ~/.zshrc
    sed -i '/# Enable spelling correction/ a setopt CORRECT' ~/.zshrc
    sed -i '/# Adjust the correction style (optional)/ a SPROMPT="CORRECT %{$fg[red]%}%R%f%{$reset_color%} ? "' ~/.zshrc
    sudo chsh -s $(which zsh)
    source ~/.zshrc
}

neovim() {
# Install other stuff and make it usable as a IDE for JS and J
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

mkdir -p ~/.config/nvim && touch ~/.config/nvim/init.vim
cat <<EOF > ~/.config/nvim/init.vim
" Your Neovim configuration goes here

"clip board"
set clipboard=unnamedplus

"allow mouse"
set mouse=a

" Example: Set your leader key
let mapleader = "\<Space>"

" Example: Install and manage plugins using Vim-Plug
call plug#begin('~/.config/nvim/plugged')

" Essential Plugins
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'scrooloose/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'mhinz/vim-startify'
Plug 'tpope/vim-fugitive'

" Code Editing and Productivity
Plug 'tpope/vim-surround'
Plug 'tpope/vim-commentary'
Plug 'jiangmiao/auto-pairs'
Plug 'preservim/nerdcommenter'
Plug 'itchyny/lightline.vim'

" Git Integration
Plug 'tpope/vim-git'

" Themes
Plug 'morhetz/gruvbox'

" Autocompletion and Linting with Coc.nvim
Plug 'neoclide/coc.nvim', {'branch': 'release'}
let g:coc_global_extensions = ['coc-java', 'coc-tsserver', 'coc-python', 'coc-sh']

" Syntax Highlighting and Linting for Various Languages
Plug 'elzr/vim-json'
Plug 'leafgarland/typescript-vim'
Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'vim-python/python-syntax'

" Add any other plugins you prefer below this line

" End of Vim-Plug section
call plug#end()

" Configure Coc.nvim for JavaScript, Python, Java, and Bash
if has('nvim')
  autocmd FileType javascript,json setl omnifunc=coc#_select_confirm
  autocmd FileType python setl omnifunc=coc#_select_confirm
  autocmd FileType java setl omnifunc=coc#_select_confirm
  autocmd FileType sh setl omnifunc=coc#_select_confirm
endif

EOF
nvim -c 'PlugInstall | q | q'
}

_git() {
    read -p "Enter your Git user.name: " git_name
    read -p "Enter your Git user.email: " git_email
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
}

_docker(){
    # Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the repository to Apt sources:
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

_aws_gcloud() {
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip
    sudo ./aws/install
    
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
    sudo apt-get install apt-transport-https ca-certificates gnupg
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
    sudo apt-get update && sudo apt-get install google-cloud-sdk
    sudo aws configure
    sudo gcloud init
}

_desktop(){
    sudo apt update && sudo apt install -y $APT_APPS
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    flatpak install flathub
    sudo npm install -g nodemon react jest typescript
    wget https://download.jetbrains.com/toolbox/jetbrains-toolbox-2.0.4.17212.tar.gz -O jb.tar.gz
    sudo tar -xzf jb.tar.gz -C /opt
    sudo ./opt/jetbrains-toolbox
}    

_server(){
    #Mount Drives
mkdir /jelly /storage
#mkdir /jelly/downloads #/storage/config /jelly/movies /jelly/shows
#make it so of already written it wont write again
echo "UUID=9067c3d0-babc-4ffa-b8b9-4212a4fe4cea /jelly ext4 defaults 0 0" >> /etc/fstab
echo "UUID=16cc2161-d654-4cf4-a954-a7d61892d08c /storage ext4 defaults 0 0" >> /etc/fstab
systemctl daemon-reload && mount --all

#software install
apt install -y nvidia-cuda-toolkit nvidia-driver

#dpkg --configure -a
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
      && curl -s -L https://nvidia.github.io/libnvidia-container/debian11/libnvidia-container.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt update
apt install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

#ffmpeg with nvidia hardware acceleration
apt -y install build-essential pkg-config checkinstall git libfaac-dev libgpac-dev ladspa-sdk-dev libunistring-dev libbz2-dev libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev libxfixes-dev texi2html yasm zlib1g-dev
mkdir ~/nvidia/ && cd ~/nvidia/
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers && make install
cd ~/nvidia/
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
apt install -y build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev
cd ~/nvidia/ffmpeg/
./configure --pkg-config-flags="--static" --enable-nonfree --enable-gpl --enable-version3 \
--enable-libmp3lame --enable-libvpx --enable-libopus \
--enable-opencl --enable-libxcb \
--enable-opengl --enable-nvenc --enable-vaapi \
--enable-vdpau --enable-ffplay --enable-ffprobe \
--enable-libxvid \
--enable-libx264 --enable-libx265 --enable-openal \
 --enable-cuda-nvcc --enable-cuvid --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64
make -j $(nproc)
ls -l ffmpeg
echo 'export PATH=$PATH:/root/nvidia/ffmpeg' >> .bashrc

apt -y autoremove
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always --net=host -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/storage portainer/portainer-ce:latest 

}

main() {
    echo "debian_desktop (dd), debian_server (ds), debian_cloud_server (dcs), cloud9 (c9), custom (c)"
    read -p "what kind of linux computer would you like to set up? " action
    
    case $action in
        debian_desktop|dd)
                if hostnamectl | grep "Debian"; then
                    _setup
                    _desktop
                    _zsh
                    _neovim
                    _docker
                    _git
                    _aws_gcloud
                    echo "done"
            
                else
                    echo "OS not supported or found."
                    exit 1
                fi
            
            ;;
        debian_server|ds)
               if hostnamectl | grep "Debian"; then
                    _setup
                    _server
                    _zsh
                    _neovim
                    _docker
                    _git
                    _aws_gcloud
                    echo "done"
            
                else
                    echo "OS not supported or found."
                    exit 1
                fi
            
            ;;
        debian_cloud_server|dcs)
               if hostnamectl | grep "Debian"; then
                    _setup
                    echo "done"
            
                else
                    echo "OS not supported or found."
                    exit 1
                fi
            
            ;;
        cloud9|c9)
               if hostnamectl | grep "Ubuntu"; then
                    _setup
                    _zsh
                    _docker
                    _git
                    _aws_gcloud
                    echo "done"
            
                else
                    echo "OS not supported or found."
                    exit 1
                fi
            
            ;;
        custom|c)
            echo"custom"s
            ;;
    esac
}
main