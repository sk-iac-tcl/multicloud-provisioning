output "sample_app_url" {
  value = "${ibm_compute_vm_instance.worker.*.ipv4_address}"
}