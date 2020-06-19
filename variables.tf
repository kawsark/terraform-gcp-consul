variable "gcp_project" {
  description = "Name of GCP project"
}

variable "gcp_region" {
  description = "primary region"
  default     = "us-east1"
}

variable "retry_join_wan" {
  description = "Optionally provide one or more IP addresses for WAN join, defaults to empty string"
  default = "[\"\"]"
}


variable "consul_license" {
  description = "Optionally enter a Consul Enterprise license here. Relevant when using enterprise consul_url."
  default     = "asdf"
}

variable "consul_url" {
  description = "enter a Consul download URL here"
  default     = "https://releases.hashicorp.com/consul/1.8.0/consul_1.8.0_linux_amd64.zip"
}

variable "create_gossip_encryption_key" {
  description = "Set this to 0 to allow a randomly generated gossip encryption key"
  default     = true
}

variable "gossip_encryption_key" {
  description = "If create_gossip_encryption_key=1, enter your own gossip encryption key here by using consul keygen command."
  default     = ""
}

variable "image" {
  description = "An OS image to provision: https://cloud.google.com/compute/docs/images#os-compute-support"
  default     = "ubuntu-os-cloud/ubuntu-1804-lts"
}

variable "owner" {
  default = "demouser"
}

variable "consul_dc" {
  default = "us-east1"
}

variable "primary_dc" {
  default = "us-east1"
}

variable "consul_server_count" {
  default = 3
}

variable "environment" {
  default = "lab"
}

# Deploy applications
variable "apps" {
  type = map
  description = "Use the format: app_name = [\"tag\",\"app_port\",\"start_command\"]"
  default = {
    counting = ["v0.0.2", "9001", "sudo docker run --net=host -p 9001:9001 -d --name counting hashicorp/counting-service:0.0.2"]
    dashboard = ["v0.0.4", "9002", "sudo docker run --net=host -d -e=COUNTING_SERVICE_URL=http://localhost:5000 --name dashboard hashicorp/dashboard-service:0.0.4"]
    hashicat-url = ["v1", "9090", "sudo docker run --net=host -d -e=MESSAGE=\"{\"url\":\"http://placekitten.com/800/500\"}\" -e=LISTEN_ADDR=\"0.0.0.0:9090\" -e=NAME=hashicat-url --name hashicat-url nicholasjackson/fake-service:v0.10.0"]
    hashicat-metadata = ["v1", "9190", "sudo docker run --net=host -d -e=MESSAGE=\"{\"enable_ratings\":\"True\",\"caption\":\"Welcome to Cam Meowlicious App\"}\" -e=LISTEN_ADDR=\"0.0.0.0:9190\" -e=NAME=hashicat-metadata --name hashicat-metadata nicholasjackson/fake-service:v0.10.0"]
  }
}

# Optional static IP
variable "consul_static_ip_array" {
  description = "Optionally provide an array of static IP addresses for Consul servers. Otherwise, ephemeral IPs will be assigned"
  default     = ["", "", "", "", ""]
}

# TLS related variables
variable "common_name" {
  description = "A CN for CA and generated certificates"
  default     = "consul-gcp.hashidemos.io"
}

variable "organization_name" {
  description = "A OU for CA and generated certificates"
  default     = "research"
}

