#!/bin/bash
##  Author: https://github.com/trevor256
##  Usage: run on Ubuntu 22.04.1 to fix Blender HIP rendering 

# Adds green to echos
    GREEN="$(tput setaf 2)"
    NONE="$(tput sgr0)"


echo "${GREEN} No HIP blender fix${NONE}"
# https://askubuntu.com/questions/1434988/blender-3-3-does-not-recognize-my-gpu-for-hip-on-ubuntu-20-04
    echo "username" read username
    sudo usermod -a -G video $username 
    sudo usermod -a -G render $username


## Detecting AMD gpu
radeon (){
    echo "Detecting AMD GPU"
    if hostnamectl | grep -q "Ubuntu 22.04.1 LTS"; 
then
    echo "${GREEN} Install Radeon & Huion graphics tablet driver${NONE}"
    wget https://repo.radeon.com/amdgpu-install/22.40/ubuntu/jammy/amdgpu-install_5.4.50401-1_all.deb
    sudo dpkg -i amdgpu-install_5.4.50401-1_all.deb -y
    amdgpu-install -y

else
    echo "No radeon GPU found"
    echo "you have ___"
fi
}


## Detecting OS version 
if hostnamectl | grep -q "Ubuntu 22.04.1 LTS"; 
then
    radeon
else
    echo "need Ubuntu 22.04"
    echo "you have ___"
fi
