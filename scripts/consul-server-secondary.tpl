#!/bin/bash
echo "~~~~~~~ Consul startup script - begin ~~~~~~~"

# Set variables
export PATH="$${PATH}:/usr/local/bin"
export local_ip="$(curl -s -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)"

# Install pre-reqs
# TODO: figure out better OS detection logic
if [  -n "$(uname -a | grep -i Ubuntu)" ]; then
    echo "Proceeding as Ubuntu install"
    apt-get update -y
    apt install curl unzip jq -y
else
    echo "Proceeding as Redhat/CentOS install"
    yum update -y
    yum install curl unzip jq -y
fi  

# Download consul
echo "Downloading consul"
cd /tmp
curl "${consul_url}" -o consul.zip
unzip consul.zip
mv consul /usr/local/bin/consul
chmod +X /usr/local/bin/consul
echo "Installed consul binary: $(consul --version)"

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

# Install Docker compose
# https://www.digitalocean.com/community/tutorials/how-to-install-docker-compose-on-ubuntu-16-04
sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Build Envoy
sleep 10
echo "Starting application proxy"
cat <<EOF >Dockerfile
FROM consul:latest
FROM envoyproxy/envoy:v1.8.0
COPY --from=0 /bin/consul /bin/consul
ENTRYPOINT ["dumb-init", "consul", "connect", "envoy"]
EOF
sudo docker build -t consul-envoy .

# Install git and add key
# https://help.github.com/en/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
sudo apt-get install git -y

# Download repo
cd /tmp
git clone ${repo_clone_url}
cd docker-consul-connect-demo
sudo docker-compose up

# Install dnsmasq
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo apt-get install dnsmasq -y
sudo systemctl enable dnsmasq
sudo systemctl start dnsmasq

echo "Waiting for docker compose - sleep 60"
sleep 60

echo "Applying enterprise license"
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_ADDR="http://127.0.0.1:8500"

function consul_has_leader {
  try=0
  max=12
  consul_has_leader=$(consul operator raft list-peers | grep leader)
  while [ -z "$consul_has_leader" ]
  do
    touch "/tmp/consul-try-$try"
    if [[ "$try" == '12' ]]; then
      echo "Giving up on consul operator raft list-peers after 12 attempts."
      break
    fi
    ((try++))
    echo "Consul leader is not elected, sleeping 10 secs [$try/$max]"
    sleep 10
    consul_has_leader=$(consul operator raft list-peers | grep leader)
  done

  echo "Consul cluster has leader, proceeding with Initialization"
}

# Wait for consul to elect a leader
consul_has_leader

consul members
consul license put ${consul_license}
consul license get > /tmp/consul_license_status

# Setup bash profile
cat <<PROFILE | sudo tee /etc/profile.d/consul.sh
export CONSUL_HTTP_SSL_VERIFY=false
export CONSUL_HTTP_ADDR="http://127.0.0.1:8500"
#export CONSUL_CACERT="$${CONSUL_TLS_DIR}/consul-ca.crt"
PROFILE

echo "~~~~~~~ Consul startup script - end ~~~~~~~"
