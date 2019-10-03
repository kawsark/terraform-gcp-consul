provider "google" {
  region  = var.gcp_region
  project = var.gcp_project
}

data "google_compute_default_service_account" "default" {
}

module "consul-cluster" {
  source = "./google_compute_instance"
  image  = var.image

  tags = ["consul-${var.gcp_project}-${var.consul_dc}"]

  labels = {
    environment = "dev"
    app         = "consul"
    ttl         = "24h"
    owner       = var.owner
  }

  server_count                = 3
  use_static_ip               = true
  static_ip_array             = var.consul_static_ip_array
  gcp_project                 = var.gcp_project
  gcp_region                  = var.gcp_region
  instance_name               = "consul-${var.consul_dc}"
  use_default_service_account = false
  service_account_email       = data.google_compute_default_service_account.default.email
  startup_script              = data.template_file.consul_userdata.rendered
  os_pd_ssd_size              = "12"
}

module "counting-service" {
  source = "./google_compute_instance"
  image  = var.image

  tags = ["consul-${var.gcp_project}-${var.consul_dc}"]

  labels = {
    environment = "dev"
    app         = "counting-service"
    ttl         = "24h"
    owner       = var.owner
    sequence    = module.consul-cluster[2].id
  }

  server_count = 1

  gcp_project                 = var.gcp_project
  gcp_region                  = var.gcp_region
  instance_name               = "counting-service-${var.consul_dc}"
  use_default_service_account = false
  service_account_email       = data.google_compute_default_service_account.default.email
  startup_script              = data.template_file.counting_userdata.rendered
  os_pd_ssd_size              = "12"
}

module "dashboard-service" {
  source = "./google_compute_instance"
  image  = var.image

  tags = ["consul-${var.gcp_project}-${var.consul_dc}"]

  labels = {
    environment = "dev"
    app         = "dashboard-service"
    ttl         = "24h"
    owner       = var.owner
    sequence    = module.counting-service[2].id
  }

  server_count = 1

  gcp_project                 = var.gcp_project
  gcp_region                  = var.gcp_region
  instance_name               = "dashboard-service-${var.consul_dc}"
  use_default_service_account = false
  service_account_email       = data.google_compute_default_service_account.default.email
  startup_script              = data.template_file.dashboard_userdata.rendered
  os_pd_ssd_size              = "12"
}
