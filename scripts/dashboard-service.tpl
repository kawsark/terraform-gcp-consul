#!/bin/bash
echo "~~~~~~~ App service startup script - begin ~~~~~~~"

# Set variables
export PATH="$${PATH}:/usr/local/bin"
export local_ip="$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)"
export external_ip="$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/access-configs/0/external-ip)"

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

# Install pre-reqs
echo "Proceeding as Ubuntu install"
sudo apt install curl unzip jq -y

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
#cat <<-EOF > $${CONSUL_CONFIG_DIR}/acl.hcl
#acl = {
#  enabled = true,
#  default_policy = "allow",
#  enable_token_persistence = true
#}
#EOF

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

# https://www.consul.io/docs/commands
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_SSL=false
export CONSUL_HTTP_ADDR="http://127.0.0.1:8500"
export CONSUL_GRPC_ADDR="http://127.0.0.1:8502"


# Write consul client configuration
cat <<EOF > /etc/consul.d/client.hcl
datacenter = "${dc}"
primary_datacenter = "${primary_dc}"
enable_central_service_config = true
data_dir = "$${CONSUL_DATA_DIR}"
bind_addr = "$${local_ip}"
client_addr = "0.0.0.0"
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
verify_incoming_rpc = false
auto_encrypt = {
  tls = true
}
ports = {
  http = 8500,
  https = -1,
  grpc = 8502
}
connect = {
  enabled = true
}
EOF

echo "writing service definition file for ${app_name}"
cat <<EOF > "$${CONSUL_CONFIG_DIR}/${app_name}.json"
{
  "service": {
    "name": "${app_name}",
    "tags": [
      "${app_tag}"
    ],
    "port": ${app_port},
    "connect": {
      "sidecar_service": {
        "proxy": {
          "upstreams" : [{
            "destination_name":"counting",
            "local_bind_port":5000
          }]
        }
      } 
    },
    "check": {
      "id":"${app_name}-http-check",
      "name":"HTTP health check on port ${app_port}",
      "method": "GET",
      "http": "http://$${local_ip}:${app_port}/health",
      "Interval": "2s"
    }
  }
}
EOF

echo "writing service definition file for ${app2_name}"
cat <<EOF > "$${CONSUL_CONFIG_DIR}/${app2_name}.json"
{
  "service": {
    "name": "${app2_name}",
    "tags": [
      "${app2_tag}"
    ],
    "port": ${app2_port},
    "connect": {
      "sidecar_service": {} 
    },
    "check": {
      "id":"${app2_name}-http-check",
      "name":"HTTP health check on port ${app2_port}",
      "method": "GET",
      "http": "http://$${local_ip}:${app2_port}/health",
      "Interval": "2s"
    }
  }
}
EOF

chown -R consul:consul "$${CONSUL_CONFIG_DIR}"
chown -R consul:consul "$${CONSUL_DATA_DIR}"
chown -R consul:consul "$${CONSUL_TLS_DIR}"

# Adding 180 seconds delay for consul servers
echo "~~~~~~ Going to sleep for 180 seconds to allow Consul server start ~~~~~"

echo "Starting consul client"
systemctl enable consul.service
systemctl daemon-reload
systemctl start consul.service
sleep 5
consul members

# Install dnsmasq
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo apt-get install dnsmasq -y
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

# Remove any existing containers or images
docker rm -f $(docker ps -aq)
docker rmi $(docker images -q)

# Run application
echo "Starting application ${app_name}"
echo ${app_cmd} > /tmp/app.sh
chmod +x /tmp/app.sh
# Clear any previous instances (useful for reprovision scenarios)
sudo docker rm -f ${app_name} 
/tmp/app.sh

# Run application 2
echo "Starting application ${app2_name}"
echo ${app2_cmd} > /tmp/app2.sh
cat /tmp/app2.sh | sed -e s/'{'/'"{'/ -e s/'}'/'}"'/ > /tmp/app2.sed.sh
chmod +x /tmp/app2.sed.sh
# Clear any previous instances (useful for reprovision scenarios)
sudo docker rm -f ${app2_name} 
/tmp/app2.sed.sh

# Start Envoy proxy
sleep 10
echo "Starting application proxy"
cat <<EOF >Dockerfile
FROM consul:latest
FROM envoyproxy/envoy:v1.13.1
RUN cat /etc/os-release
COPY --from=0 /bin/consul /bin/consul
RUN apt-get update -y && apt-get install wget -y
RUN wget -O /bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_amd64
RUN chmod +x /bin/dumb-init
ENTRYPOINT ["dumb-init"]
EOF
sudo docker build -t consul-envoy .

# Clear any previous instances (useful for reprovision scenarios)
sudo docker rm -f ${app_name}-sidecar-proxy
sudo docker run -d --network host --name ${app_name}-sidecar-proxy \
  consul-envoy consul connect envoy -sidecar-for ${app_name} -admin-bind 0.0.0.0:19000

sudo docker rm -f ${app2_name}-sidecar-proxy
sudo docker run -d --network host --name ${app2_name}-sidecar-proxy \
  consul-envoy consul connect envoy -sidecar-for ${app2_name} -admin-bind 0.0.0.0:19001

# Re-register service in case there was an issue with Envoy setup
sleep 10
consul services deregister $${CONSUL_CONFIG_DIR}/${app_name}.json
consul services register $${CONSUL_CONFIG_DIR}/${app_name}.json
consul services deregister $${CONSUL_CONFIG_DIR}/${app2_name}.json
consul services register $${CONSUL_CONFIG_DIR}/${app2_name}.json

# Setup bash profile
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_ADDR="http://127.0.0.1:8500"
export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
PROFILE

# Start mesh gateway
# Clear any previous instances (useful for reprovision scenarios)
sudo docker rm -f gateway-${dc}
sudo docker run -d --network host --name gateway-${dc} -v "$${CONSUL_TLS_DIR}/consul-ca.crt:/consul-ca.crt" \
  consul-envoy consul connect envoy -mesh-gateway -register -service "gateway-${dc}" -ca-file=/consul-ca.crt \
  -address "$${local_ip}:18502" -wan-address "$${external_ip}:18502" -admin-bind 0.0.0.0:19005 

echo "~~~~~~~ App startup script - end ~~~~~~~"
