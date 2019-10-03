# Render userdata
data "template_file" "consul_userdata" {
  template = file("${path.module}/scripts/consul-server.tpl")
  vars = {
    consul_url          = var.consul_url
    dc                  = var.consul_dc
    primary_dc          = var.primary_dc
    retry_join          = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    retry_join_wan      = var.retry_join_wan
    consul_server_count = var.consul_server_count
    consul_license      = var.consul_license
    ca_crt              = module.root_tls_self_signed_ca.ca_cert_pem
    leaf_crt            = module.leaf_tls_self_signed_cert.leaf_cert_pem
    leaf_key            = module.leaf_tls_self_signed_cert.leaf_private_key_pem
    consul_encrypt      = var.create_gossip_encryption_key ? random_id.consul_encrypt.b64_std : var.gossip_encryption_key
  }
}

data "template_file" "counting_userdata" {
  template = file("${path.module}/scripts/counting-service.tpl")
  vars = {
    consul_url     = var.consul_url
    app_name       = "counting"
    app_tag        = "v0.0.2"
    app_port       = "9001"
    app_cmd        = "sudo docker run --net=host -p 9001:9001 -d --name counting hashicorp/counting-service:0.0.2"
    gcp_project    = var.gcp_project
    gcp_region     = var.gcp_region
    dc             = var.consul_dc
    primary_dc          = var.primary_dc
    retry_join     = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_license = var.consul_license
    ca_crt         = module.root_tls_self_signed_ca.ca_cert_pem
    leaf_crt       = module.leaf_tls_self_signed_cert.leaf_cert_pem
    leaf_key       = module.leaf_tls_self_signed_cert.leaf_private_key_pem
    consul_encrypt = var.create_gossip_encryption_key ? random_id.consul_encrypt.b64_std : var.gossip_encryption_key
  }
}

data "template_file" "dashboard_userdata" {
  template = file("${path.module}/scripts/dashboard-service.tpl")
  vars = {
    consul_url     = var.consul_url
    app_name       = "dashboard"
    app_tag        = "v0.0.4"
    app_port       = "9002"
    app_cmd        = "sudo docker run --net=host -d -e=COUNTING_SERVICE_URL=http://localhost:5000 --name dashboard hashicorp/dashboard-service:0.0.4"
    gcp_project    = var.gcp_project
    gcp_region     = var.gcp_region
    dc             = var.consul_dc
    primary_dc          = var.primary_dc
    retry_join     = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_license = var.consul_license
    ca_crt         = module.root_tls_self_signed_ca.ca_cert_pem
    leaf_crt       = module.leaf_tls_self_signed_cert.leaf_cert_pem
    leaf_key       = module.leaf_tls_self_signed_cert.leaf_private_key_pem
    consul_encrypt = var.create_gossip_encryption_key ? random_id.consul_encrypt.b64_std : var.gossip_encryption_key
  }
}

