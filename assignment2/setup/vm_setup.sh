#!/bin/bash -x

# Submitted by Group 8: Benjamin Murphy (A00805865), Nao Hashizume (A01022269) 

SETUP_FILEPATH="setup"
TODOAPP_USER="todoapp"
HTTP_PORT="80"
SYSTEMD_FILE_PATH="/etc/systemd/system"
TODOAPP_CONFIG_DIR_PATH="/home/todoapp/app/config"
DATABASE_FILE_PATH="$SETUP_FILEPATH/database.js"
NGINX_FILE_PATH="$SETUP_FILEPATH/nginx.conf"
TODOAPP_SERVICE_PATH="$SETUP_FILEPATH/todoapp.service"

# Copy all files in setup to VM
scp -r "$SETUP_FILEPATH/setup" lab1vm:~

ssh lab1vm << EOF

    # Add todoapp user 
    add_user(){
        echo "Creating todoapp user..."
        sudo useradd -p P@ssw0rd "$TODOAPP_USER"
        echo "Completed creating todoapp user!!!"
    }

    # Install packages
    install_packages(){
        echo "Installin required packages..."
        sudo yum update -y
        sudo yum install -y nodejs npm mongodb-server nginx git
        sudo systemctl enable mongod
        sudo systemctl start mongod
        echo "Completed installing required packages!!!"
    }

    # firewall config
    config_firewall(){
        echo "Configuring firewall..."
        sudo firewall-cmd --zone=public --add-service=http
        sudo firewall-cmd --zone=public --add-port="$HTTP_PORT"/tcp
        sudo firewall-cmd --runtime-to-permanent
        echo "Completed configuring firewall!!!"
    }

    # Setup Todo App
    setup_todoapp(){
        echo "Configuring Todo app..."
	sudo chmod 755 /home/todoapp
        git clone https://github.com/timoguic/ACIT4640-todo-app.git app
        cd app
        npm install -q
	cd
	sudo mv app /home/todoapp
        sudo chown todoapp /home/todoapp/app
        cd
	pwd
        sudo cp -f "$DATABASE_FILE_PATH" "$TODOAPP_CONFIG_DIR_PATH"
        sudo cp -f "$NGINX_FILE_PATH" "/etc/nginx/nginx.conf"
        sudo cp -f "$TODOAPP_SERVICE_PATH" "$SYSTEMD_FILE_PATH"

        echo "Setting up program..."
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl daemon-reload
        sudo systemctl enable todoapp
        sudo systemctl start todoapp
	sudo sed -i '/SELINUX=enforcing/c\SELINUX=permissive' /etc/selinux/config
	sudo shutdown -hr now
    }

add_user
install_packages
config_firewall
setup_todoapp

exit
EOF
