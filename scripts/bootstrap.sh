#!/usr/bin/env bash
set -euo pipefail

echo "Starting Vagrant VMs..."
vagrant up --provision=virtualbox

echo "Pause for SSH to become available..."
sleep 8

echo "Run Ansible playbook (use --private-key to point to the Vagrant private key):"
echo "ansible-playbook -i ansible/inventories/vagrant.ini ansible/site.yml -u vagrant --private-key ~/.vagrant.d/insecure_private_key"