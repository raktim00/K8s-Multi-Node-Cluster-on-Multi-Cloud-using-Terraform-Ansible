resource "null_resource" "inventory_creation" {
    
    depends_on = [
      aws_instance.aws_k8s_master,
      azurerm_linux_virtual_machine.az_k8s_slave,
      google_compute_instance.gcp_k8s_slave
    ]

provisioner "local-exec" {
  command = <<EOT
cat <<EOF > ../ansible-ws/inventory
[aws_k8s_master_host]
${aws_instance.aws_k8s_master.public_ip}

[az_gcp_k8s_slave_host]
${google_compute_instance.gcp_k8s_slave.network_interface.0.access_config.0.nat_ip}
${azurerm_linux_virtual_machine.az_k8s_slave.public_ip_address}
EOF
    EOT
  }
}