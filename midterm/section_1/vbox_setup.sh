#!/bin/bash -x

vbmg () { /mnt/c/Program\ Files/Oracle/VirtualBox/VBoxManage.exe "$@"; }

NET_NAME="NETMIDTERM"
STUDENT_NUM="A00805865"
VM_NAME="MIDTERM4640"

SUBNET="192.168.10.0/24"
SSH_RULE="SSH:TCP:[127.0.0.1]:12922:[192.168.10.10]:22"
HTTP_RULE="HTTP:TCP:[127.0.0.1]:12980:[192.168.10.10]:80"

clean_all(){
	vbmg natnetwork remove --netname "$NET_NAME"
	#vbmg unregistervm "$VM_NAME" --delete
}

create_network(){
	vbmg natnetwork add --netname "$NET_NAME" \
		--network "$SUBNET" \
		--enable \
		--dhcp off \
		--port-forward-4 "$SSH_RULE" \
		--port-forward-4 "$HTTP_RULE"
}

modify_vm(){
	vbmg modifyvm "$VM_NAME" --name "$STUDENT_NUM" \
		--nic1 "natnetwork" \
		--nat-network1 "$NET_NAME"

	vbmg startvm "$STUDENT_NUM"
}

ssh_to_vm(){
	while /bin/true; do
		ssh midterm \
			exit
		if [ $? -ne 0 ]; then
			echo "Midterm server is not up, sleeping..."
			sleep 2
		else
			break
		fi
done
}

clean_all
create_network
modify_vm
ssh_to_vm
