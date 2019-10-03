variable "gcp_project" {
  description = "Name of GCP project"
}

variable "gcp_region" {
  description = "primary region"
  default     = "us-east1"
}

variable "retry_join_wan" {
  description = "Optionally provide one or more IP addresses for WAN join"
  default = ""
}


variable "consul_license" {
  description = "Optionally enter a Consul Enterprise license here. Relevant when using enterprise consul_url."
  default     = "asdf"
}

variable "consul_url" {
  description = "enter a Consul download URL here"
  default     = "https://releases.hashicorp.com/consul/1.6.1/consul_1.6.1_linux_amd64.zip"
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
  default     = "ubuntu-os-cloud/ubuntu-1604-lts"
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

# Optional static IP
variable "consul_static_ip_array" {
  description = "Optionally provide an array of static IP addresses for Consul servers. Otherwise, ephemeral IPs will be assigned"
  default     = ["", "", "", "", ""]
}

# TLS related variables
variable "common_name" {
  description = "A CN for CA and generated certificates"
  default     = "therealk.com"
}

variable "organization_name" {
  description = "A OU for CA and generated certificates"
  default     = "research"
}

