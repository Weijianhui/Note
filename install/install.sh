#!/bin/bash

TMP_DISK_PATH=$(df | grep mmcblk1p9 | awk '{print $6}')
TMP=1
PATH_LEN=${#TMP_DISK_PATH}
if [ $PATH_LEN != 50 ];then
    DISK_PATH=$TMP_DISK_PATH$TMP
else
    DISK_PATH=$TMP_DISK_PATH
fi
LNPATH=/home/linaro/disk
SERVICE_HOME=/home/linaro/disk/zq
SCRIPT_HOME=/usr/bin
SMARTCLASS_HOME=$SERVICE_HOME/Server
SCA_HOME=$SERVICE_HOME/Server-SCA
SRS_HOME=$SERVICE_HOME/srs
SYS_SER_HOME=/lib/systemd/system
WS=`pwd`

run_as_linaro(){
	sudo -H -u linaro bash -c "$1"
}

#Check if the script run as root
if [ $UID != 0 ]; then
	echo "===>I'm not root,use 'sudo ./install.sh' to run me!!!<==="
	exit 1
fi

echo "===>>>install dependence<<<==="

cd dependencies
unzip adb.zip
unzip libgdiplus.zip
cd adb
dpkg -i *.deb
cd ../libgdiplus
dpkg -i *.deb
cd $WS

echo "***>Done<***"

echo "===>>>Start Installation<<<==="

#Determine whether the Services.zip exists
if [ ! -f "Services.zip" ];then
	echo "Services.zip is not exist,copy Services.zip to the same folder as install.sh!"
	exit 1
fi

#Stop running services
pids=$(ps -ef|grep SmartClass|grep -v grep|awk '{print $2}')
if [ "$pids" != "" ];then kill -9 $pids;fi
pids=$(ps -ef|grep Zonekey|grep -v grep|awk '{print $2}')
if [ "$pids" != "" ];then kill -9 $pids;fi
echo "Wait for Services stop"
sleep 5

#Create soft link for disk
if [ -h $LNPATH ];then
	echo "--->Soft link for disk has exist!<---"
elif [ -d $LNPATH ];then
	echo "--->Folder for disk has exist!<---"
else
	echo "--->Create soft link for disk<---"
	run_as_linaro "ln -s $DISK_PATH $LNPATH"
	chmod 777 $LNPATH
fi
echo "***>Done<***"

#Make folder for Service
if [ -d "$SERVICE_HOME" ];then
	echo "--->Service folder has exist,will clean up it!<---"
	rm -rf $SERVICE_HOME
	run_as_linaro "mkdir $SERVICE_HOME"
else 
	echo "--->Create Service folder!<---"
	run_as_linaro "mkdir $SERVICE_HOME"
fi
echo "***>Done<***"

echo "--->Copy startup script!<---"
cp ./startup_script/* $SCRIPT_HOME
chmod +x $SCRIPT_HOME/zk_smartclass_ctl
chmod +x $SCRIPT_HOME/zk_sca_ctl
chmod +x $SCRIPT_HOME/zk_srs_ctl
chmod +x $SCRIPT_HOME/zk_check_ctl
echo "***>Done<***"

echo "--->Copy linux service file to system folder!<---"
cp ./linux_service/* $SYS_SER_HOME
systemctl daemon-reload
systemctl enable smartclass.service
systemctl enable check.service
systemctl enable srs.service
systemctl enable sca.service
if [ -f "$SYS_SER_HOME/nginx.service" ];then
	systemctl disable nginx.service
	rm $SYS_SER_HOME/nginx.service
fi
echo "***>Done<***"

echo "--->Copy service to disk!<---"
run_as_linaro "cp ./Services.zip $SERVICE_HOME"
run_as_linaro "cp ./SCA.zip $SERVICE_HOME"
run_as_linaro "cp ./srs5-server.zip $SERVICE_HOME"
echo "***>Done<***"

echo "--->Unzip zip file!<---"
run_as_linaro "unzip $SERVICE_HOME/Services.zip -d $SERVICE_HOME 1>/dev/null 2>&1"
run_as_linaro "unzip $SERVICE_HOME/SCA.zip -d $SERVICE_HOME 1>/dev/null 2>&1"
run_as_linaro "unzip $SERVICE_HOME/srs5-server.zip -d $SRS_HOME 1>/dev/null 2>&1"
echo "***>Done<***"

echo "--->Add executable right for service file<---"
chmod +x $SMARTCLASS_HOME/SmartClass.Web
chmod +x $SCA_HOME/Zonekey.SCA.Server
chmod +x $SRS_HOME/srs
echo "***>Done<***"

echo "--->Add partition auto mount!<---"
if [ -h /home/linaro/disk ];then
	rm /home/linaro/disk
fi
cp ./conf_file/fstab /etc

echo "===>Installation complated!<==="
echo "===>Server will restart in 5 seconds<==="
sleep 5
init 6