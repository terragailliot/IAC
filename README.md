# <h1 align="center" >IAC Configuration & Solution Files
#### <img align="left" width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/docker.svg"> docker folder - contains docker compose YAML files 
#### <img align="left" width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/solutions.svg"> solutions folder - contains solutions to various issues 
#### <img align="left" width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/terraform.svg"> terraform folder - contains .tf scripts to build cloud solutions 

</br>

## Desktop: for [Debian](https://www.debian.org/releases/testing/releasenotes) <img width="25px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/debian.svg"> - [Ubuntu](https://ubuntu.com/download/desktop) <img width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/Ubuntu.svg"> - [Fedora](https://getfedora.org) <img width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/fedora.svg"> - [Arch](https://archlinux.org/download/) <img width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/arch.svg">
</br>

```bash
curl https://raw.githubusercontent.com/trevor256/IAC/main/local/linux.sh | sudo sh
```
```bash
wget -O - -o /dev/null https://raw.githubusercontent.com/trevor256/IAC/main/local/linux.sh | sudo sh
```
</br>

## Server: for [Debian](https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-11.3.0-amd64-netinst.iso) <img width="25px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/debian.svg"> - [RHEL](https://developers.redhat.com/products/rhel/download) <img width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/rhel.svg">
</br>

```bash
curl https://raw.githubusercontent.com/trevor256/configs/main/linux_server.sh | sh
```
```bash
wget -O - -o /dev/null https://raw.githubusercontent.com/trevor256/configs/main/linux_server.sh | sh
```
</br>
</br>
</br>

## Desktop: [Windows 11](https://www.microsoft.com/software-download/windows11) <img width="30px" src="https://raw.githubusercontent.com/trevor256/trevor256/main/imgs/Windows.svg"><br/>

```powershell
. { iwr -useb https://raw.githubusercontent.com/trevor256/configs/main/desktop_windows.ps1 } | iex; install
```
