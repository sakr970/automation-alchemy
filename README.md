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

```bash
.
├── README.md
├── ansible
│   ├── group_vars
│   ├── inventories
│   └── roles
│       ├── app
│       │   ├── defaults
│       │   ├── files
│       │   ├── handlers
│       │   ├── tasks
│       │   ├── templates
│       │   └── vars
│       ├── base
│       │   ├── defaults
│       │   ├── files
│       │   ├── handlers
│       │   ├── tasks
│       │   ├── templates
│       │   └── vars
│       ├── docker
│       │   ├── defaults
│       │   ├── files
│       │   ├── handlers
│       │   ├── tasks
│       │   ├── templates
│       │   └── vars
│       ├── hardening
│       │   ├── defaults
│       │   ├── files
│       │   ├── handlers
│       │   ├── tasks
│       │   ├── templates
│       │   └── vars
│       └── netdata
│           ├── defaults
│           ├── files
│           ├── handlers
│           ├── tasks
│           ├── templates
│           └── vars
├── docker
│   ├── backend
│   └── frontend
└── terraform
    ├── env
    └── modules

```