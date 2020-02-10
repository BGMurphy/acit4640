#!/bin/bash

#vbmg () { /mnt/c/Program\ /mnt/c/'Program Files'/Oracle/VirtualBox/VBoxManage.exe "$@"; }
vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="TODO4640"
PXE_SERVER="PXE4640"
VM_NAME="LAB1VM"
WEB_PORT="8000"
#VM_PATH () { /home/ben/windows/VirtualBox VMs/ "$@"; }
#VM_PATH="/home/ben/labs/lab2"
#FILE_NAME="${VM_PATH}${VM_NAME}.vdi"
ISO_PATH="/Users/Ben/Downloads/CentOS-7-x86_64-Minimal-1908.iso"
SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"

VBOX_FILE=$(vbmg showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_PATH=$(dirname "$VBOX_FILE")
FILE_NAME="$VM_NAME.vdi"

PXE_FILE=$(vbmg showvminfo "$PXE_SERVER" | sed -ne "$SED_PROGRAM")
PXE_PATH=$(dirname "$PXE_FILE")
PXE_NAME="$PXE_NAME.vdi"

clean_all () {
	echo "Removing previous config..."
#	vbmg modifyvm ${PXE_SERVER} --nic1 natnetwork --nat-network1 ${NET_NAME}
	vbmg natnetwork remove --netname ${NET_NAME}
	vbmg unregistervm ${VM_NAME} --delete
}

create_network () {
	echo "Creating network"
	vbmg natnetwork add --netname ${NET_NAME} --network "192.168.230.0/24" --enable --ipv6 off
	vbmg natnetwork modify --netname ${NET_NAME} --dhcp off
	vbmg natnetwork modify \
	  --netname ${NET_NAME} --port-forward-4 "ssh:tcp:[]:13022:[192.168.230.10]:22"	
	vbmg natnetwork modify \
	  --netname ${NET_NAME} --port-forward-4 "http:tcp:[]:13080:[192.168.230.10]:80"
	vbmg natnetwork modify \
	  --netname ${NET_NAME} --port-forward-4 "ssh2:tcp:[]:12222:[192.168.230.200]:22"
	vbmg natnetwork modify \
	  --netname ${NET_NAME} --port-forward-4 "8080:tcp:[]:13000:[192.168.230.10]:8080"
}

create_vm () {
	echo "Creating VM"
	vbmg createvm --name ${VM_NAME} --ostype "RedHat_64" --register
	vbmg modifyvm ${VM_NAME} --memory 2048 --cpus 1 --audio none
	vbmg modifyvm ${VM_NAME} --nic1 natnetwork --nat-network1 ${NET_NAME}
	vbmg modifyvm ${PXE_SERVER} --nic1 natnetwork --nat-network1 ${NET_NAME}
	vbmg createmedium disk --filename "$VM_PATH\\$FILE_NAME" --size 10000 --format "VDI"
	vbmg storagectl ${VM_NAME} --name "$VM_PATH\\$FILE_NAME" --add sata --controller "IntelAhci"
	#vbmg storagectl ${VM_NAME} --name "VM_PATH\\FILE_NAME" --add ide --controller PIIX4
	vbmg storageattach ${VM_NAME} --storagectl "$VM_PATH\\$FILE_NAME" --port 1 --type hdd --medium "$VM_PATH\\$FILE_NAME" 
	vbmg storageattach ${VM_NAME} --storagectl "$VM_PATH\\$FILE_NAME" --port 0 --type dvddrive --medium ${ISO_PATH}
	vbmg modifyvm  ${VM_NAME} --boot1 disk
	vbmg modifyvm  ${VM_NAME} --boot2 net
	vbmg modifyvm  ${VM_NAME} --boot3 none
	vbmg modifyvm  ${VM_NAME} --boot4 none
}

start_vms () {
	echo "Starting PXE server..."
	vbmg startvm ${PXE_SERVER}
	while /bin/true; do
		ssh -i ~/.ssh/acit_admin_id_rsa -p 12222 \
			-o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
			-q admin@localhost exit
		if [ $? -ne 0 ]; then
			echo "PXE server is not up, sleeping..."
			sleep 2
		else
			break
		fi

	done
	scp -r setup pxe:/var/www/lighttpd/files
	vbmg startvm ${VM_NAME}
	while /bin/true; do
		ssh -i ~/.ssh/acit_admin_id_rsa -p 13022 \
			-o ConnectTimeout=2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
			-q admin@localhost exit
		if [ $? -ne 0 ]; then
			echo "lab1vm is not up, sleeping..."
			sleep 2
		else
			break
		fi
	done
	vbmg controlvm ${PXE_SERVER} poweroff
	source setup/vm_setup.sh
}

clean_all
create_network
create_vm
start_vms

echo "DONE!"
