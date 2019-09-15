variable "gcp_project" {
  description = "Name of GCP project"
}

variable "gcp_region" {
  description = "region"
  default     = "us-east1"
}

variable "consul_license" {
  description = "Optionally enter a Consul Enterprise license here. Relevant when using enterprise consul_url."
  default     = "asdf"
}

variable "consul_url" {
  description = "enter a Consul download URL here"
  default     = "https://releases.hashicorp.com/consul/1.5.3/consul_1.5.3_linux_amd64.zip"
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

variable "consul_server_count" {
  default = 3
}

variable "environment" {
  default = "lab"
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

