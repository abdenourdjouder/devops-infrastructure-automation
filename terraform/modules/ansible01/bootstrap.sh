#!/bin/bash

set -e

# Hostname
hostnamectl set-hostname ansible01

# System packages
apt-get update
apt-get install -y \
  ansible \
  python3-pip \
  python3-venv

# Python environment dedicated to Ansible/WinRM
python3 -m venv /opt/ansible-venv

/opt/ansible-venv/bin/pip install --upgrade pip
/opt/ansible-venv/bin/pip install pywinrm

# Ansible Windows collection
ansible-galaxy collection install ansible.windows

# Ansible directory structure
mkdir -p /etc/ansible/inventory
mkdir -p /etc/ansible/group_vars
mkdir -p /etc/ansible/playbooks

# Ansible configuration
cat > /etc/ansible/ansible.cfg <<'EOF'
[defaults]
inventory = /etc/ansible/inventory/hosts
host_key_checking = False
interpreter_python = auto_silent
EOF

# Ansible inventory
cat > /etc/ansible/inventory/hosts <<EOF
[rmia]
RMIA01 ansible_host=${rmia01_private_ip}
RMIA02 ansible_host=${rmia02_private_ip}

[rmia:vars]
ansible_connection=winrm
ansible_port=5986
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
EOF