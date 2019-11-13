provider "ibm" {
  softlayer_username = "${var.ibm_sl_username}"
  softlayer_api_key  = "${var.ibm_sl_api_key}"
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"

  provisioner "local-exec" {
    command = "cat > ${var.ssh_key_name} <<EOL\n${tls_private_key.ssh.private_key_pem}\nEOL"


  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.ssh_key_name}"
  }
  
}

resource "ibm_compute_ssh_key" "ibm_public_key" {
  label      = "${var.ssh_key_name}"
  public_key = "${tls_private_key.ssh.public_key_openssh}"

}


data "template_file" "createfs_master" {
  template = "${file("${path.module}/scripts/createfs_master.sh.tpl")}"


}

data "template_file" "createfs_worker" {
  template = "${file("${path.module}/scripts/createfs_worker.sh.tpl")}"


}


# Create Master Node
resource "ibm_compute_vm_instance" "master" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.master["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.master["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.master["cpu_cores"]}"
  memory               = "${var.master["memory"]}"
  disks                = ["${var.master["disk_size"]}"]
  local_disk           = "${var.master["local_disk"]}"
  network_speed        = "${var.master["network_speed"]}"
  hourly_billing       = "${var.master["hourly_billing"]}"
  private_network_only = "${var.master["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }

  provisioner "file" {
    content     = "${data.template_file.createfs_master.rendered}"
    destination = "/tmp/createfs.sh"
  }  

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh"    
    ]
  }

}


# Create Worker Node
resource "ibm_compute_vm_instance" "worker" {
  lifecycle {
    ignore_changes = ["private_vlan_id"]
  }

  count                = "${var.worker["nodes"]}"
  datacenter           = "${var.datacenter}"
  domain               = "${var.domain}"
  hostname             = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.worker["name"]),count.index + 1) }"
  os_reference_code    = "${var.os_reference}"
  cores                = "${var.worker["cpu_cores"]}"
  memory               = "${var.worker["memory"]}"
  disks                = ["${var.worker["disk_size"]}"]
  local_disk           = "${var.worker["local_disk"]}"
  network_speed        = "${var.worker["network_speed"]}"
  hourly_billing       = "${var.worker["hourly_billing"]}"
  private_network_only = "${var.worker["private_network_only"]}"
  ssh_key_ids          = ["${ibm_compute_ssh_key.ibm_public_key.id}"]
  private_vlan_id      = "${ibm_compute_vm_instance.master.0.private_vlan_id}"

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${self.ipv4_address}"
  }

  provisioner "file" {
    content     = "${data.template_file.createfs_worker.rendered}"
    destination = "/tmp/createfs.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/createfs.sh; sudo /tmp/createfs.sh"
    ]
  }

}

# Kubespray all.yml template #
data "template_file" "kubespray_all" {
  template = "${file("templates/kubespray_all.tpl")}"
  depends_on = ["ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]


}

# Kubespray k8s-cluster.yml template #
data "template_file" "kubespray_k8s_cluster" {
  template = "${file("templates/kubespray_k8s_cluster.tpl")}"

  vars = {
    kube_version        = "${var.k8s_version}"
    kube_network_plugin = "${var.k8s_network_plugin}"
    weave_password      = "${var.k8s_weave_encryption_password}"
    k8s_dns_mode        = "${var.k8s_dns_mode}"
  }

}


# Kubespray master hostname and ip list template #
data "template_file" "kubespray_hosts_master" {

  count    = 1
  template = "${file("templates/ansible_hosts.tpl")}"


  vars = {
    hostname = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.master["name"]),count.index + 1)}"
    host_ip  = "${ibm_compute_vm_instance.master.ipv4_address}"
  }

  depends_on = ["ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]
}

# Kubespray worker hostname and ip list template #
data "template_file" "kubespray_hosts_worker" {

  count    = 2
  template = "${file("templates/ansible_hosts.tpl")}"

  vars = {
    hostname = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.worker["name"]),count.index + 1)}"
    host_ip  = "${ibm_compute_vm_instance.worker.*.ipv4_address[count.index]}"
  }

  depends_on = ["ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]
}


# Kubespray master hostname list template #
data "template_file" "kubespray_hosts_master_list" {

  count    = 1
  template = "${file("templates/ansible_hosts_list.tpl")}"

  vars = {
    hostname = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.master["name"]),count.index + 1)}"    
  }

  depends_on = ["ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]
}

# Kubespray worker hostname list template #
data "template_file" "kubespray_hosts_worker_list" {

  count    = 2
  template = "${file("templates/ansible_hosts_list.tpl")}"

  vars = {

    hostname = "${format("%s-%s-%01d", lower(var.instance_prefix), lower(var.worker["name"]),count.index + 1)}"    
  }

  depends_on = ["ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]
}


#===============================================================================
# Local Files
#===============================================================================


# Create Kubespray all.yml configuration file from Terraform template #f
resource "local_file" "kubespray_all" {
  content  = "${data.template_file.kubespray_all.rendered}"
  filename = "config/group_vars/all.yml"

}

# Create Kubespray k8s-cluster.yml configuration file from Terraform template #
resource "local_file" "kubespray_k8s_cluster" {
  content  = "${data.template_file.kubespray_k8s_cluster.rendered}"
  filename = "config/group_vars/k8s-cluster.yml"

}

# Create Kubespray hosts.ini configuration file from Terraform templates #
resource "local_file" "kubespray_hosts" {
  
  content  = "[all]\n${join("", data.template_file.kubespray_hosts_master.*.rendered)}\n${join("", data.template_file.kubespray_hosts_worker.*.rendered)}\n\n[kube-master]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n\n[etcd]\n${join("", data.template_file.kubespray_hosts_master_list.*.rendered)}\n\n[kube-node]\n${join("", data.template_file.kubespray_hosts_worker_list.*.rendered)}\n\n[k8s-cluster:children]\nkube-master\nkube-node"

  filename = "config/hosts.ini"

}


#===============================================================================
# Locals
#===============================================================================

# Extra args for ansible playbooks #
locals {
  extra_args = {
    ubuntu = "-T 300"
    debian = "-T 300 -e 'ansible_become_method=su'"
    centos = "-T 300"
    rhel   = "-T 300"
  }
}

#===============================================================================
# Null Resource
#===============================================================================

# Modify the permission on the config directory
resource "null_resource" "config_permission" {
  provisioner "local-exec" {
    command = "chmod -R 700 config"
  }

  depends_on = ["local_file.kubespray_hosts", "local_file.kubespray_k8s_cluster", "local_file.kubespray_all"]

}

# Clone Kubespray repository #

resource "null_resource" "kubespray_download" {
  provisioner "local-exec" {
    command = "cd ansible && rm -rf kubespray && git clone https://github.com/kubernetes-sigs/kubespray.git"
  }

}

# Execute create Kubespray Ansible playbook #
resource "null_resource" "kubespray_create" {
  count = "${var.action == "create" ? 1 : 0}"

  provisioner "local-exec" {
    
    command = "cd ansible/kubespray && ansible-playbook -i ../../config/hosts.ini -b -u ${var.vm_user} -e \"ansible_ssh_private_key_file=../../${var.vm_pemkey}\" ${lookup(local.extra_args, var.vm_distro)} -v --flush-cache cluster.yml"

  }

  depends_on = ["local_file.kubespray_hosts", "null_resource.kubespray_download", "local_file.kubespray_all", "local_file.kubespray_k8s_cluster", "ibm_compute_vm_instance.master", "ibm_compute_vm_instance.worker"]

}


# Create the local admin.conf kubectl configuration file #
resource "null_resource" "kubectl_configuration" {
  provisioner "local-exec" {

    command = "ansible -i ${ibm_compute_vm_instance.master.ipv4_address}, -b -u ${var.vm_user} -e \"ansible_ssh_private_key_file=${var.vm_pemkey}\" ${lookup(local.extra_args, var.vm_distro)} -m fetch -a 'src=/etc/kubernetes/admin.conf dest=config/admin.conf flat=yes' all"

  }

  provisioner "local-exec" {

    command = "sed 's/lb-apiserver.kubernetes.local/${ibm_compute_vm_instance.master.ipv4_address}/g' config/admin.conf | tee config/admin.conf.new && mv config/admin.conf.new config/admin.conf && chmod 700 config/admin.conf"    
  }

  provisioner "local-exec" {
    command = "chmod 600 config/admin.conf"
  }

  depends_on = ["null_resource.kubespray_create"]
}


resource "null_resource" "create_sample_app" {
  count      = 1
  depends_on = ["null_resource.kubectl_configuration"]

  connection {
    user        = "${var.ssh_user}"
    private_key = "${tls_private_key.ssh.private_key_pem}"
    host        = "${ibm_compute_vm_instance.master.ipv4_address}"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /root",
      "yum install -y git",
      "git clone https://github.com/skcloud/hipster-shop.git",
      "kubectl create -f /root/hipster-shop/kube_manifests/"
    ]
  }
}