#!/bin/bash
echo "~~~~~~~ Counting service startup script - begin ~~~~~~~"

# Set variables
export PATH="$${PATH}:/usr/local/bin"
export local_ip="$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)"

# Install pre-reqs
echo "Proceeding as Ubuntu install"
apt-get update -y
apt install curl unzip -y

#Install Docker
sudo apt-get update -y
sudo apt-get install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo groupadd docker
sudo usermod -aG docker ubuntu
sudo systemctl enable docker

# Download vault and consul
echo "Downloading consul and vault"
apt install curl unzip -y
cd /tmp
curl "${consul_url}" -o consul.zip
unzip consul.zip
mv consul /usr/local/bin/consul
chmod +X /usr/local/bin/consul
echo "Installed consul binary: $(consul --version)"

CONSUL_CONFIG_DIR=/etc/consul.d
CONSUL_DATA_DIR=/opt/consul
CONSUL_TLS_DIR=/opt/consul/tls

echo "Creating directories"
useradd --system --home /etc/consul.d --shell /bin/false consul
mkdir -p $${CONSUL_CONFIG_DIR}
mkdir -p $${CONSUL_DATA_DIR}
mkdir -p $${CONSUL_TLS_DIR}

echo "Writing consul systemd unit file"
cat <<-EOF > /etc/systemd/system/consul.service
[Unit]
Description=consul agent
Requires=network-online.target
After=network-online.target
[Install]
WantedBy=multi-user.target
[Service]
Restart=always
RestartSec=15s
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM
EOF

# Bootstrap ACL tokens
cat <<-EOF > $${CONSUL_CONFIG_DIR}/acl.hcl
acl = {
  enabled = true,
  default_policy = "allow",
  enable_token_persistence = true
}
EOF

echo "Writing certs to TLS directories"
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul-ca.crt"
${ca_crt}
EOF
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul.crt"
${leaf_crt}
EOF
cat <<EOF | sudo tee "$${CONSUL_TLS_DIR}/consul.key"
${leaf_key}
EOF

export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"

# Write consul client configuration
cat <<EOF > /etc/consul.d/client.hcl
datacenter = "${dc}"
data_dir = "$${CONSUL_DATA_DIR}"
bind_addr = "$${local_ip}"
server = false
ui = true
log_level = "trace"
retry_join = ${retry_join}
encrypt = "${consul_encrypt}"
encrypt_verify_incoming = true
encrypt_verify_outgoing = true
ca_file = "$${CONSUL_TLS_DIR}/consul-ca.crt"
cert_file = "$${CONSUL_TLS_DIR}/consul.crt"
key_file = "$${CONSUL_TLS_DIR}/consul.key"
verify_incoming = false
verify_incoming_https = false
ports = {
    http = -1,
    https = 8501
}
EOF

echo "writing application file"
cat <<EOF > "$${CONSUL_CONFIG_DIR}/dashboard.json"
{
  "Name": "dashboard",
  "Tags": [
    "v0.0.4"
  ],
  "Port": 9002,
  "Check": {
    "Method": "GET",
    "HTTP": "http://$${local_ip}:9002/health",
    "Interval": "2s"
  }
}
EOF

chown -R consul:consul "$${CONSUL_CONFIG_DIR}"
chown -R consul:consul "$${CONSUL_DATA_DIR}"
chown -R consul:consul "$${CONSUL_TLS_DIR}"

echo "Starting consul client"
systemctl enable consul.service
systemctl daemon-reload
systemctl start consul.service
sleep 5
consul members

# Install dnsmasq
echo "server=/consul/127.0.0.1#8600" > /etc/dnsmasq.d/10-consul
apt-get install dnsmasq -y
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

# Run app container
echo ${APP_CMD} > /tmp/app.sh
chmod +x /tmp/app.sh
/tmp/app.sh

# Setup bash profile
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_HTTP_ADDR="https://127.0.0.1:8501"
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
PROFILE

echo "~~~~~~~ Counting startup script - end ~~~~~~~"