#!/bin/bash
sudo echo "Shell running ..."
current=$(cd "$(dirname "$0")"||echo ''; pwd)
readonly current
echo "Current dir : $current"

depDir=/opt/media
sudo mkdir -vp "$depDir"

srvDir="$HOME"/media
mkdir -vp "$srvDir"

backDir="$srvDir"/backup
mkdir -vp "$backDir"/zk_web
mkdir -vp "$backDir"/zk_web_ui
mkdir -vp "$backDir"/zk_snvr

echo "******************************"
echo "Initialize System Environment!"
echo "******************************"

echo "=====Change Swap====="
echo ""
sudo swapoff /swapfile
sudo fallocate -l 32G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
free -h

echo "=====Edit /etc/hosts====="
echo ""
sudo sed -i "s/127.0.1.1/#127.0.1.1/g" /etc/hosts

echo "=====Update system and install vim, ssh====="
echo ""
sudo apt update -y && sudo apt upgrade -y && sudo apt install vim openssh-server -y

echo "******************************"
echo "Install Service Dependencies!"
echo "******************************"

echo "=====Install openjdk-17====="
echo ""
sudo apt install openjdk-17-jdk-headless -y

echo "=====Install Dotnet Runtime-6.0====="
echo ""
sudo mkdir -p "$depDir"/dotnet && sudo tar zxf dotnet-sdk-6.0.407-linux-x64.tar.gz -C "$depDir"/dotnet
sudo mkdir -p "$depDir"/ffmpeg && sudo cp -r ffmpeg/* "$depDir"/ffmpeg/
sudo chmod +x "$depDir"/ffmpeg/*
sudo sed -i "$ a export PATH=$depDir/ffmpeg:$depDir/dotnet:$PATH" "$HOME"/.bashrc
sudo sed -i "$ a export DOTNET_ROOT=$depDir/dotnet" "$HOME"/.bashrc

echo "=====Check And Install Python====="
echo ""
pyver=$(python3 --version | grep 3.10)
echo "Python3 version is : $pyver"
if [ -z "$pyver" ] ; then
echo "Python version is not correct,try install."
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt install python3.10 -y
sudo apt install python3-pip -y
sudo rm /usr/bin/python
sudo ln -sf /usr/bin/python3.10 /usr/bin/python3
sudo ln -sf /usr/bin/python3 /usr/bin/python
else
echo "Python version is correct."
fi

echo "=====Install Python libs====="
echo ""
sudo apt install protobuf-compiler python3 python3-setuptools python3-pip python3-opencv python3-protobuf python3-requests -y
sudo tar -zxvf "$(ls "$current"/cuda11.6.tgz)"  -C /usr/local/
sudo cp "$current"/zk_aisrv.conf /etc/ld.so.conf.d/zk_aisrv.conf



echo "******************************"
echo "Install Zonekey Service!"
echo "******************************"

echo "=====Install AI Service====="
echo ""
sudo unzip -o "$(ls "$current"/py-3.10.zip)" -d /usr/local/zonekey
sudo apt install "$(ls "$current"/zk-aisrv-*.deb)"

echo "=====Install SNVR&Web Service====="
echo ""
if [ -d "$srvDir/snvr" ]; then
cd "$srvDir/snvr"
snvrJar=$(ls | grep SNVRService*.jar)
if [ -f "$snvrJar" ]; then
rm "$snvrJar"
fi
fi

cp -r "$current"/media/* "$srvDir"
cd "$srvDir" || echo "$srvDir not exist! "
sudo chmod -R +x ./*

echo "=====Set SNVR\Web\SRS\Assistant Service====="
echo ""
sysuser="$HOME"/.config/systemd/user
if [ ! -d "$sysuser" ]; then
mkdir -vp "$sysuser"
fi
cd "$current" || echo "$current not exist! "
cp "$current"/zk_snvr.service  "$HOME"/.config/systemd/user/zk_snvr.service
systemctl --user enable zk_snvr.service
systemctl --user start zk_snvr.service
cp "$current"/zk_web.service  "$HOME"/.config/systemd/user/zk_web.service
systemctl --user enable zk_web.service
systemctl --user start zk_web.service
cp "$current"/zk_media.service  "$HOME"/.config/systemd/user/zk_media.service
systemctl --user enable zk_media.service
systemctl --user start zk_media.service
cp "$current"/zk_assistant.service  "$HOME"/.config/systemd/user/zk_assistant.service
systemctl --user enable zk_assistant.service
systemctl --user start zk_assistant.service
cd "$srvDir" || echo "$srvDir not exist! "
sudo chmod 777 *

sudo chmod -R +x ./*


sudo apt autoremove -y

# Update AI Service File By AI_Srv
sudo systemctl stop zk_aisrv.service
sudo systemctl disable zk_aisrv.service
sudo cp "$current"/zk_aisrv.service  /etc/systemd/system/zk_aisrv.serice
sudo cp "$current"/loop.sh  /usr/local/zonekey/zk_aisrv/loop.sh
sudo systemctl enable zk_aisrv.service
sudo systemctl start zk_aisrv.service
sudo chown zonekey_ai /usr/local/zonekey/zk_aisrv/loop.sh

echo "******************************"
echo "******************************"
echo "Install Successfully! Now check AI service...... "
cd /usr/local/zonekey/zk_aisrv/test || echo "/usr/local/zonekey/zk_aisrv/test not exist! "
/usr/local/zonekey/py-3.10/bin/python3 test_one.py http://localhost:19993/session --count=20

echo "******************************"
echo "******************************"
echo "Complete successfully! You can type 'sudo reboot' to reboot system."
echo "******************************"
