#!/bin/bash -x

APP_USER="hichat"
HTTP_PORT="80"
SYSTEMD_FILE_PATH="/etc/systemd/system"
APP_CONFIG_PATH="/app"
NGINX_CONFIG_PATH="/etc/nginx"

add_user(){
	ssh midterm "
	sudo useradd -p $(openssl passwd -1 disabled) "$APP_USER"
	sudo usermod -d "$APP_CONFIG_PATH" "$APP_USER"
	sudo chmod 755 /app
	exit
	"
}

config_firewall(){
	ssh midterm "
	sudo firewall-cmd --zone=public --add-service=http
	sudo firewall-cmd --zone=public --add-port="$HTTP_PORT"/tcp
	sudo firewall-cmd --runtime-to-permanent
	"
}

install_packages(){
	ssh midterm "
	sudo yum update -y
	sudo yum install -y nodejs npm mongodb-server nginx git
	sudo systemctl enable mongod && sudo systemctl start mongod
	"
}

install_app() {
	ssh midterm "
	sudo git clone https://github.com/wayou/HiChat /app
	cd /app
	sudo npm install -q
	sudo chown -R hichat /app
	"
}

copy_files(){
	scp -r ./setup midterm:~
	ssh midterm "
	sudo cp -f /home/midterm/setup/hichat.service "$SYSTEMD_FILE_PATH"
	sudo cp -f /home/midterm/setup/nginx.conf "$NGINX_CONFIG_PATH"
		      
	sudo systemctl daemon-reload
	sudo systemctl enable nginx
	sudo systemctl start nginx
	sudo systemctl enable hichat
	sudo systemctl start hichat
	"	
}

add_user
install_packages
config_firewall
install_app
copy_files

