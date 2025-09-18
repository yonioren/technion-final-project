#!/bin/bash

### Ansible installation
add-apt-repository universe
apt update
apt install -y ansible

mkdir -p /etc/ansible

#update /etc/hosts file
cat <<EOF >> /etc/hosts
#App servers group:
${app1_ip} app1
${app2_ip} app2


EOF

# Create ansible.cfg file
cat <<EOF > /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/hosts
EOF

# Create Ansible hosts file (Inventory)
cat <<EOF > /etc/ansible/hosts
[apps]
app1
app2

[apps:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/KP.pem

[all:vars] #Ignore ssh fingerprints
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

### Flag to prevent race
touch /tmp/finished_userdata
