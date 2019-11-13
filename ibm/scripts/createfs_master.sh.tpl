#!/bin/bash


#Disable password authentication on public network
sed -i "s/^PasswordAuthentication yes$/PasswordAuthentication no/" /etc/ssh/sshd_config
cat <<EOL | tee -a /etc/ssh/sshd_config
Match Address 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
    PasswordAuthentication yes
EOL
systemctl restart sshd