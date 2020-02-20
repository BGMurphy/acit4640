#!/bin/bash -x

TODOAPP_USER="todoapp"
HTTP_PORT="80"
SYSTEMD_FILE_PATH="/etc/systemd/system"
TODOAPP_CONFIG_PATH="/home/todoapp/app/config"
NGINX_CONFIG_PATH="/etc/nginx"

add_user(){
    sudo useradd -p $(openssl passwd -1 P@ssw0rd) "$TODOAPP_USER"
    sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers;
}

install_packages(){
    sudo yum update -y
    sudo yum install -y nodejs npm mongodb-server nginx git
    sudo systemctl enable mongod && sudo systemctl start mongod
}

config_firewall(){
    sudo firewall-cmd --zone=public --add-service=http
    sudo firewall-cmd --zone=public --add-port="$HTTP_PORT"/tcp
    sudo firewall-cmd --runtime-to-permanent
}

setup_todoapp(){
    sudo chmod 755 /home/todoapp
    ls -la /home
    git clone https://github.com/timoguic/ACIT4640-todo-app.git app
    sudo mv app /home/todoapp/app
    cd /home/todoapp/app
    npm install -q 
    sudo chown -R todoapp /home/todoapp/app
    sudo sed -i '/SELINUX=enforcing/c\SELINUX=permissive' /etc/selinux/config
}

copy_files(){
    sudo cp -f /home/admin/setup/database.js "$TODOAPP_CONFIG_PATH"
    sudo cp -f /home/admin/setup/todoapp.service "$SYSTEMD_FILE_PATH"
    sudo cp -f /home/admin/setup/nginx.conf "$NGINX_CONFIG_PATH"
  
    sudo systemctl daemon-reload
    sudo systemctl enable nginx 
    sudo systemctl start nginx
    sudo systemctl enable todoapp
    sudo systemctl start todoapp
}

add_user
install_packages
config_firewall
setup_todoapp
copy_files

