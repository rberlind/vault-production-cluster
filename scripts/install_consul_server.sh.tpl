#!/usr/bin/env bash
set -e

# Install packages
${install_unzip}

# Download Consul into some temporary directory
curl -L "${consul_download_url}" > /tmp/consul.zip

# Unzip it
cd /tmp
sudo unzip consul.zip
sudo mv consul /usr/local/bin
sudo chmod 0755 /usr/local/bin/consul
sudo chown root:root /usr/local/bin/consul

# Setup the configuration
cat <<EOF >/tmp/consul-config
${consul_config}
EOF
IP_ADDRESS=$(curl http://instance-data/latest/meta-data/local-ipv4)
sed -i "s/IP_ADDRESS/$IP_ADDRESS/g" /tmp/consul-config
sed -i "s/TAG_VALUE/${tag_value}/g" /tmp/consul-config
sed -i "s/CONSUL_NODES/${consul_nodes}/g" /tmp/consul-config
sudo mkdir /etc/consul.d
sudo mv /tmp/consul-config /etc/consul.d/consul-config.json

# Setup the init script
cat <<EOF >/tmp/systemd
[Unit]
Description=Consul Agent
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
EnvironmentFile=/etc/consul.d/consul-config.json
ExecStart=/usr/local/bin/consul agent -config-dir /etc/consul.d $FLAGS
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
User=root
Group=root
LimitNOFILE=8192

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/systemd /etc/systemd/system/consul.service
sudo chmod 0664 /etc/systemd/system/consul.service

sudo mkdir -pm 0755 /opt/consul/data

# Start Consul
sudo systemctl enable consul
sudo systemctl start consul
