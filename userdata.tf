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
    app_tag        = var.apps["counting"][0]
    app_port       = var.apps["counting"][1]
    app_cmd        = var.apps["counting"][2]
    app2_name       = "hashicat-url"
    app2_tag        = var.apps["hashicat-url"][0]
    app2_port       = var.apps["hashicat-url"][1]
    app2_cmd        = var.apps["hashicat-url"][2]    
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
    app_tag        = var.apps["dashboard"][0]
    app_port       = var.apps["dashboard"][1]
    app_cmd        = var.apps["dashboard"][2]
    app2_name       = "hashicat-metadata"
    app2_tag        = var.apps["hashicat-metadata"][0]
    app2_port       = var.apps["hashicat-metadata"][1]
    app2_cmd        = var.apps["hashicat-metadata"][2]    
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

