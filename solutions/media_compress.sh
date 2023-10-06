#!/bin/sh
###########################################################
#  Author https://github.com/trevor256
#  script compresses media with ffmpeg
#  Linux OS (any)
###########################################################


#Compile ffmpeg with nvidia hardware acceleration
<< 'MULTILINE-COMMENT'
sudo apt-get -y install build-essential pkg-config checkinstall git libfaac-dev libgpac-dev ladspa-sdk-dev libunistring-dev libbz2-dev \
  libjack-jackd2-dev libmp3lame-dev libsdl2-dev libopencore-amrnb-dev libopencore-amrwb-dev libvpx-dev libx264-dev libx265-dev libxvidcore-dev libopenal-dev libopus-dev \
  libsdl1.2-dev libtheora-dev libva-dev libvdpau-dev libvorbis-dev libx11-dev \
  libxfixes-dev texi2html yasm zlib1g-dev
mkdir ~/nvidia/ && cd ~/nvidia/
git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers && sudo make install
cd ~/nvidia/
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
apt install build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev
cd ~/nvidia/ffmpeg/
MULTILINE-COMMENT

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

$TYPE=("mp4" "mkv")
#compress any video into a .mp4 with h265 compretion using hardware acceleration
for t in *.mkv; do ffmpeg -hwaccel cuda -i "$t" -c:v libx264 "compressed/$(basename "${t%.*}").mp4"; done