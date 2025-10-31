# Automation Alchemy

## 

- Terraform (Infrastructure as Code)
- Ansible (Configuration Management)
- GitHub Actions (CI/CD)
- Docker (Containerization)

### install require tools

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# Install Ansible
sudo apt install ansible -y

# Install other tools
sudo apt install git curl jq tree -y
```



## Quick start:
```bash
vagrant up
ansible-playbook -i ansible/inventories/vagrant.ini ansible/site.yml -u vagrant --private-key ~/.vagrant.d/insecure_private_key

./scripts/bootstrap.sh
```

---

## Contains:
- Vagrantfile: creates 5 VMs
- ansible/: playbooks and roles
- docker/: app Dockerfiles
- scripts/: helper scripts


Verify Ansible can reach the Vagrant VMs, expected: "pong" from each host (app, web1, web2, loadbalancer, backup, ci)
```bash
ansible all -i ansible/inventories/vagrant.ini -u vagrant --private-key ~/.vagrant.d/insecure_private_key -m ping
```

set SSH connection with devops user
```bash
mkdir -p ansible/roles/base/files
cp ~/.ssh/id_rsa.pub ansible/roles/base/files/devops_id_rsa.pub
# OR generate a key if you don't have one:
# ssh-keygen -t ed25519 -f ~/.ssh/id_devops -N ""
# cp ~/.ssh/id_devops.pub ansible/roles/base/files/devops_id_rsa.pub
```

```yml
- name: Ensure application directory exists
  file:
    path: /opt/diagnostic_backend
    state: directory
    owner: devops
    group: devops
    ---
    - name: Ensure application directory exists
      file:
        path: /opt/diagnostic_backend
        state: directory
        owner: devops
        group: devops
        mode: '0755'

    - name: Copy backend Dockerfile and app
      copy:
        src: ../../docker/backend/
        dest: /opt/diagnostic_backend/
        owner: devops
        group: devops
        mode: '0755'

    - name: Build backend Docker image
      become: yes
      community.docker.docker_image:
        build:
          path: /opt/diagnostic_backend/
        name: diagnostic_backend
        tag: latest

    - name: Ensure backend container is running
      become: yes
      community.docker.docker_container:
        name: diagnostic_backend
        image: diagnostic_backend:latest
        state: started
        restart_policy: always
        published_ports:
          - "5000:5000"
        env:
          NODE_ENV: production
```