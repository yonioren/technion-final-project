#!/bin/bash
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


# Create Ansible hosts file (Inventory)
cat <<EOF > /etc/ansible/hosts
[apps]
app1
app2

[apps:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=/home/ubuntu/.ssh/KP.pem
ansible_python_interpreter=/usr/libexec/platform-python


[all:vars] #Ignore ssh fingerprints
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'



EOF

# Create ansible.cfg file
cat <<EOF > /etc/ansible/ansible.cfg



[defaults]
inventory = /etc/ansible/hosts



EOF
