# Render userdata
data "template_file" "consul_userdata" {
  template = "${file("${path.module}/scripts/consul-server.tpl")}"
  vars {
    consul_url          = "${var.consul_url}"
    dc                  = "${var.consul_dc}"
    retry_join          = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_server_count = "${var.consul_server_count}"
    consul_license      = "${var.consul_license}"
    ca_crt              = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt            = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key            = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt      = "${random_id.consul_encrypt.b64_std}"
  }
}

data "template_file" "counting_userdata" {
  template = "${file("${path.module}/scripts/counting-service.tpl")}"
  vars {
    consul_url     = "${var.consul_url}"
    APP_CMD        = "sudo docker run -p 9001:9001 -d --name counting-service hashicorp/counting-service:0.0.2"
    gcp_project    = "${var.gcp_project}"
    gcp_region     = "${var.gcp_region}"
    dc             = "${var.consul_dc}"
    retry_join     = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_license = "${var.consul_license}"
    ca_crt         = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt       = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key       = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt = "${random_id.consul_encrypt.b64_std}"
  }
}


data "template_file" "dashboard_userdata" {
  template = "${file("${path.module}/scripts/dashboard-service.tpl")}"
  vars {
    consul_url     = "${var.consul_url}"
    APP_CMD        = "sudo docker run -p 9002:9002 -d --name dashboard-service hashicorp/dashboard-service:0.0.4"
    gcp_project    = "${var.gcp_project}"
    gcp_region     = "${var.gcp_region}"
    dc             = "${var.consul_dc}"
    retry_join     = "[\"provider=gce zone_pattern=${var.gcp_region}-. tag_value=consul-${var.gcp_project}-${var.consul_dc}\"]"
    consul_license = "${var.consul_license}"
    ca_crt         = "${module.root_tls_self_signed_ca.ca_cert_pem}"
    leaf_crt       = "${module.leaf_tls_self_signed_cert.leaf_cert_pem}"
    leaf_key       = "${module.leaf_tls_self_signed_cert.leaf_private_key_pem}"
    consul_encrypt = "${random_id.consul_encrypt.b64_std}"
  }
}