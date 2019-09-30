variable "server_count" {
  default = 1
}

variable "tags" {
  default = ["demo", "terraform"]
}

variable "labels" {
  type = map(string)
  default = {
    environment = "demo"
    app         = "demo"
    ttl         = "24h"
    owner       = "kawsar"
  }
}

variable "os_pd_ssd_size" {
  description = "Size of OS disk in GB"
  default     = "10"
}

variable "gcp_region" {
  description = "GCP region, e.g. us-east1"
  default     = "us-east1"
}

variable "gcp_project" {
  description = "Name of GCP project"
}

variable "machine_type" {
  description = "GCP machine type"
  default     = "n1-standard-2"
}

variable "instance_name" {
  description = "GCP instance name"
  default     = "terraform-demo"
}

variable "image" {
  description = "image to build instance from in the format: image-family/os. See: https://cloud.google.com/compute/docs/images#os-compute-support"
  default     = "ubuntu-os-cloud/ubuntu-1404-lts"
}

variable "startup_script" {
  description = "A startup script passed as metadata"
  default     = "touch /tmp/default_startup_script"
}

variable "use_default_service_account" {
  description = "If set to 1, it will attach the default compute service account to instance."
  default     = true
}

variable "service_account_email" {
  description = "If using a non-default service account, then set the email here"
  default     = "my-service-acct@my-project.iam.gserviceaccount.com"
}

variable "use_static_ip" {
  description = "Set this to true and support a static_ip_array to use a static IP"
  default     = false
}

variable "static_ip_array" {
  description = "provide a list of static IPs, should be the same length as qty. of nodes"
  type        = list(string)
  default     = ["", "", ""]
}

