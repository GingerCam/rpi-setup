#!/bin/bash

CURRENT_HOSTNAME=$(sudo raspi-config nonint get_hostname)
NEW_HOSTNAME="Galactica"
USER="cam"
ftp_conf="/etc/vsftpd.conf"
programs=(
    "git"
    "htop"
    "python3"
    "python3-pip"
    "curl"
    "vim"
    "nmap"
    "gcc"
    "neofetch"
    "qemu"
    "wget"
    "samba"
    "samba-common-bin"
    "vsftpd"
)

ftp() {
    if grep -q "#write_enable=YES" $ftp_conf; then
        sed -i "s/#write_enable=YES/write_enable=YES"
    fi
    sudo systemctl restart vsftpd
}

samba(){
    if ! grep -q "Galactica" /etc/samba/smb.conf; then
        echo "[Galactica]" >> /etc/samba/smb.conf
        echo "Comment = Pi shared folder" >> /etc/samba/smb.conf
        echo "Path = /" >> /etc/samba/smb.conf
        echo "Browseable = yes" >> /etc/samba/smb.conf
        echo "Writeable = Yes" >> /etc/samba/smb.conf
        echo "only guest = no" >> /etc/samba/smb.conf
        echo "create mask = 0777" >> /etc/samba/smb.conf
        echo "directory mask = 0777" >> /etc/samba/smb.conf
        echo "Public = yes" >> /etc/samba/smb.conf
        echo "Guest ok = no" >> /etc/samba/smb.conf
    fi

}

main() {
    sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo rpi-update
    for program in $programs; do
        sudo apt install -y $program
    done
    if ! (cat /etc/passwd | grep -q 'cam'); then
        sudo useradd -m -G wheel,dialout,sudo cam
        export PATH=$PATH:~/.local/bin
        cd /home/cam
        mkdir git
    fi 
    wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
    chmod +x pishrink.sh
    sudo mv pishrink.sh /usr/local/bin
    rm pishrink.sh
    echo "alias update='sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y && clear'" >> /home/cam/.bashrc
    
    if (sudo raspi-config nonint get_wifi_country) != "GB"; then
        sudo raspi-config nonint do_wifi_country GB
    fi
    if (sudo raspi-config nonint get_overscan) != 1; then
        sudo raspi-config nonint do_overscan 1
    fi
    if (sudo raspi-config nonint get_ssh) != 0; then
        sudo raspi-config nonint do_ssh 0
    fi
    if (sudo raspi-config nonint get_hostname) != $NEW_HOSTNAME; then
        sudo raspi-config nonint do_hostname $NEW_HOSTNAME
    fi

    ftp()
    samba()
    echo ""
    echo "Please enter a Samba password"
    sudo smbpasswd -a cam
    if (sudo raspi-config nonint get_can_expand) != 0; then
        sudo raspi-config nonint do_expand_rootfs
    fi
    echo "Setup complete"
    sleep 5
    sudo reboot
    
}
