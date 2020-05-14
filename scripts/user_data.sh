#!/bin/bash

# Install vault dependencies

# Some sane options.
set -e # Exit on first error.
set -x # Print expanded commands to stdout.

#install unzip

sudo apt -y install unzip

# download the vault instance
wget -q http://releases.hashicorp.com/vault/1.4.1/vault_1.4.1_linux_amd64.zip
unzip vault_1.4.1_linux_amd64.zip
sudo mv vault /usr/bin
rm vault_1.4.1_linux_amd64.zip

# configure the vault service

cat > vault.service <<'EOF'
[Unit]
Description="Vault - A tool for managing secrets"
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/vault.d/vault.hcl
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
ProtectSystem=full
ProtectHome=read-only
PrivateTmp=yes
PrivateDevices=yes
SecureBits=keep-caps
AmbientCapabilities=CAP_IPC_LOCK
Capabilities=CAP_IPC_LOCK+ep
CapabilityBoundingSet=CAP_SYSLOG CAP_IPC_LOCK
NoNewPrivileges=yes
ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGINT
Restart=on-abnormal
RestartSec=5
TimeoutStopSec=30
StartLimitInterval=60
StartLimitIntervalSec=60
StartLimitBurst=3
LimitNOFILE=65536
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target

EOF

# configure the vault server
sudo mv vault.service /etc/systemd/system/

cat > vault.hcl <<'EOF'
  ui = true
  listener "tcp" {
    address       = "0.0.0.0:8200"
    tls_disable      = 1
  }
  storage "file" {
    path  = "/var/lib/vault/data"
  }

  api_addr = "http://0.0.0.0:8200"

EOF

if [ ! -d "/etc/vault.d" ];
then
  sudo mkdir /etc/vault.d/
fi

sudo mv vault.hcl /etc/vault.d/
sudo systemctl enable vault
sudo systemctl start vault
sudo systemctl status vault

export VAULT_ADDR='http://127.0.0.1:8200'

vault operator init

function create_user {
  declare -r user=$1 password=$2
  vault login -method=userpass username="$user" password="$password"
}

create_user "sample" "sample"
