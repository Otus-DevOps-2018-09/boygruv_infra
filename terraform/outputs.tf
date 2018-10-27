output "vm1_external_ip" {
  value = "${element(google_compute_instance.app.*.network_interface.0.access_config.0.assigned_nat_ip,0)}"
}

output "vm2_external_ip" {
  value = "${element(google_compute_instance.app.*.network_interface.0.access_config.0.assigned_nat_ip,1)}"
}

output "app_loadbalancer_ip" {
  value = "${google_compute_forwarding_rule.reddit-app-lb.ip_address}"
}
