#!/bin/bash

if [[ $EUID -ne 0 ]]; then
    echo This script required elevated privileges.
    exit 1
fi
clear
banner() {
    echo -e "--------------------------------------------------------------------------"
    echo -e "  ██████╗ ██████╗ ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗"
    echo -e "  ██╔══██╗██╔══██╗██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
    echo -e "  ██████╔╝██████╔╝██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝"
    echo -e "  ██╔══██╗██╔═══╝ ██║    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝"
    echo -e "  ██║  ██║██║     ██║    ███████║███████╗   ██║   ╚██████╔╝██║"
    echo -e "  ╚═╝  ╚═╝╚═╝     ╚═╝    ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝"
    echo -e "--------------------------------------------------------------------------"
}

CURRENT_HOSTNAME=$(sudo raspi-config nonint get_hostname)
hostname="Galactica"
USER=cam
lite="false"
argon="false"
ftp_conf=/etc/vsftpd.conf
programs=(
    'git'
    'htop'
    'python3'
    'python3-pip'
    'curl'
    'vim'
    'nmap'
    'gcc'
    'neofetch'
    'qemu'
    'wget'
    'samba'
    'samba-common-bin'
    'vsftpd'
    'macchanger'
    'aircrack-ng'
    'cockpit'
    'tuned'
)

while [[ "${1}" != "" ]]; do
	case "${1}" in
    	--lite)    lite="true" ;;
        --argon)     argon="true" ;;
        --hostname)     hostname=$2 ;;
        --user)     USER=$2 ;;
    esac
    
    shift 1
done


sleep 4

ftp() {
    clear
    echo "[*] Setting up FTP server"
    if grep -q "#write_enable=YES" $ftp_conf; then
        sed -i "s/#write_enable=YES/write_enable=YES"
    fi
    sudo systemctl restart vsftpd
    clear
    echo "[/] Setup FTP server"
}

samba() {
    clear
    echo "[*] Setting up Samba Server"
    if ! grep -q "Galactica" /etc/samba/smb.conf; then
        echo "[Galactica]" >>/etc/samba/smb.conf
        echo "Comment = Pi shared folder" >>/etc/samba/smb.conf
        echo "Path = /" >>/etc/samba/smb.conf
        echo "Browseable = yes" >>/etc/samba/smb.conf
        echo "Writeable = Yes" >>/etc/samba/smb.conf
        echo "only guest = no" >>/etc/samba/smb.conf
        echo "create mask = 0777" >>/etc/samba/smb.conf
        echo "directory mask = 0777" >>/etc/samba/smb.conf
        echo "Public = yes" >>/etc/samba/smb.conf
        echo "Guest ok = no" >>/etc/samba/smb.conf
    fi
    sudo systemctl restart smbd
    clear
    echo "[/] Setup Samba server"
}

main() {
    banner
    echo "Lite mode = $lite"
    echo "Argon one = $argon"
    echo "Hostname = $hostname"
    echo "---------------------"
    echo ""
    echo "[*] Installing Packages"
    sleep 1
    sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y 
    for program in "${programs[@]}"; do
        DEBIAN_FRONTEND=noninteractive sudo apt install -yq "$program"
    done

    if lite = "false"; then
        sudo apt install raspberrypi-ui-mods
        sudo systemctl disable lightdm
    fi
    clear
    echo "[/] Installed Packages"
    sleep 4
    echo "[*] Setting up user"
        sleep 1
    if ! (cat /etc/passwd | grep -q '$USER'); then
        sudo useradd -m -G sudo $USER
        cd /home/$USER
        mkdir git
    fi
    wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
    chmod +x pishrink.sh
    sudo mv pishrink.sh /usr/local/bin

    if [ $argon = "true" ]; then
        curl https://download.argon40.com/argon1.sh | bash
    fi
    if ! grep -q "update=" /home/$USER/.bashrc; then
        echo "alias update='sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && clear'" >>/home/cam/.bashrc
    fi
    if [[ $(sudo raspi-config nonint get_wifi_country) != "GB" ]]; then
        sudo raspi-config nonint do_wifi_country GB
    fi
    if [[ $(sudo raspi-config nonint get_overscan) != 1 ]]; then
        sudo raspi-config nonint do_overscan 1
    fi
    if [[ $(sudo raspi-config nonint get_ssh) != 0 ]]; then
        sudo raspi-config nonint do_ssh 0
    fi

    ftp 
    samba

    echo ""
    echo -e "raspberry\nraspberry\n" | sudo smbpasswd -a $USER -s
    echo 'cam:raspberry' | sudo chpasswd
    if [[ $(sudo raspi-config nonint get_can_expand) != 0 ]]; then
        sudo raspi-config nonint do_expand_rootfs
    fi
    if [[ $(sudo raspi-config nonint get_hostname) != $hostname ]]; then
        sudo raspi-config nonint do_hostname $hostname
    fi
    echo "Setup complete"
    echo "Your system will now reboot"
    sleep 5
    sudo reboot
}

main
