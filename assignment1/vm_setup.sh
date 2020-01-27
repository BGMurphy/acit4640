#!/bin/bash -x

# Submitted by Group 8: Benjamin Murphy (A00805865), Nao Hashizume (A01022269) 

SETUP_FILEPATH="setup"
TODOAPP_USER="todoapp"
HTTP_PORT="8080"
SYSTEMD_FILE_PATH="/etc/systemd/system"
TODOAPP_CONFIG_DIR_PATH="/home/todoapp/app/config"
DATABASE_FILE_PATH="$SETUP_FILEPATH/database.js"
NGINX_FILE_PATH="$SETUP_FILEPATH/nginx.conf"
TODOAPP_SERVICE_PATH="$SETUP_FILEPATH/todoapp.service"

# Copy all files in setup to VM
scp -r "$SETUP_FILEPATH" todoapp:~

ssh todoapp << EOF

    # Add todoapp user 
    add_user(){
        echo "Creating todoapp user..."
        sudo useradd -p $(openssl passwd -1 P@ssw0rd) "$TODOAPP_USER"
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

        echo "Setting up web app..."
        git clone https://github.com/timoguic/ACIT4640-todo-app.git app
        cd app
        npm install -q
	cd 
        sudo mv app /home/todoapp
        sudo chown todoapp /home/todoapp/app

        cd
        sudo cp -f "$DATABASE_FILE_PATH" "$TODOAPP_CONFIG_DIR_PATH"
        sudo cp -f "$NGINX_FILE_PATH" "$TODOAPP_CONFIG_DIR_PATH"
        sudo cp -f "$TODOAPP_SERVICE_PATH" "$SYSTEMD_FILE_PATH"

        echo "Setting up program..."
        sudo systemctl enable nginx
        sudo systemctl start nginx
        sudo systemctl daemon-reload
        sudo systemctl enable todoapp
        sudo systemctl start todoapp
    }

add_user
install_packages
config_firewall
setup_todoapp

exit
EOF
