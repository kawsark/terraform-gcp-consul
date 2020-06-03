output "consul_servers" {
  value = module.consul-cluster.*.external_ip
}

output "counting_service_ip" {
  value = module.counting-service.*.external_ip
}

output "dashboard_service_ip" {
  value = module.dashboard-service.*.external_ip
}

