#!/bin/bash 
sudo systemctl stop eibd.service
sudo systemctl disable eibd.service
service eibd stop
sudo update-rc.d eibd remove

TEMP_DIR=`mktemp -d /tmp/eibd.XXXXXX`
cd $TEMP_DIR
check_run()  {
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "error with $1" >&2
	exit
    fi
    return $status
}

# Check for root priviledges
if [ $(id -u) != 0 ]
then
	echo "Superuser (root) priviledges are required to install eibd"
	echo "Please do 'sudo -s' first"
	exit 1
fi



echo "*****************************************************************************************************"
echo "*                              Del PTHSEM V2.0.8 libraries                                   *"
echo "*****************************************************************************************************"
sudo rm /etc/eibd/pthsem_VERSION
echo $LD_LIBRARY_PATH
export LD_LIBRARY_PATH="/usr/local/lib"
sudo ldconfig 
rm $TEMP_DIR/pthsem-2.0.8

echo "*****************************************************************************************************"
echo "*                              del BCUSDK V0.0.5 libraries                                   *"
echo "*****************************************************************************************************"

rm $TEMP_DIR/bcusdk-0.0.5 
rm /etc/eibd/bcusdk_VERSION

echo "*****************************************************************************************************"
echo "*                                 Del eibd startup script                                      *"
echo "*****************************************************************************************************"
rm /etc/init.d/eibd 
rm /etc/logrotate.d/eibd
rm /etc/default/eibd
rm /var/log/eibd.log
rm /etc/systemd/system/eibd.service 
sudo systemctl --system daemon-reload
sudo update-rc.d eibd remove
rm -R /etc/eibd