output "vm_public_ip" {
  description = "Public IP of the shortener VM — use this as VM_HOST in GitHub Actions secrets"
  value       = oci_core_instance.shortener_vm.public_ip
}

output "vm_private_ip" {
  description = "Private IP within the VCN"
  value       = oci_core_instance.shortener_vm.private_ip
}

output "ssh_command" {
  description = "Ready-to-run SSH command to connect to your VM"
  value       = "ssh -i ssh-key-2026-06-08.key ubuntu@${oci_core_instance.shortener_vm.public_ip}"
}