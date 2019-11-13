variable ibm_sl_username {
  description = "IBM Cloud Infrastructure Username"
  default     = ""
}

variable ibm_sl_api_key {
  description = "IBM Cloud Infrastructure Password"
  default     = ""
}


variable ssh_key_name {
  description = "SSH Public Key Label"
  default     = "iac-mc"
}

variable "ssh_user" {
  description = "SSH User"
  default     = "root"
}


variable "vm_pemkey" {
  description = "SSH pem key"
  default     = "iac-mc"
}



variable "instance_prefix" {
  default = "iac-mc"
}


variable datacenter {
  description = "Softlayer Data Center code"
  default     = "seo01"
}

variable "domain" {
  description = "Instance Domain"
  default     = "sk.com"
}

variable "os_reference" {
  description = "OS Reference Code: ubuntu: UBUNTU_16_64 Redhat: REDHAT_7_64"
  default     = "CENTOS_7_64"
}


variable "master" {
  type = "map"

  default = {
    nodes                = "1"
    name                 = "master"
    cpu_cores            = "4"
    disk_size            = "100"     // GB
    local_disk           = false
    memory               = "8192"
    network_speed        = "100"
    private_network_only = false
    hourly_billing       = true
  }
}


variable "worker" {
  type = "map"

  default = {
    nodes                = "2"
    name                 = "worker"
    cpu_cores            = "2"
    disk_size            = "100"     // GB
    local_disk           = false
    memory               = "4096"
    network_speed        = "100"
    private_network_only = false
    hourly_billing       = true
  }
}

variable "action" {
  description = "Which action have to be done on the cluster (create, add_worker, remove_worker, or upgrade)"
  default     = "create"
}


variable "k8s_version" {
  description = "Version of Kubernetes that will be deployed"
  default     = "1.16.2"
}


variable "k8s_network_plugin" {
  description = "Kubernetes network plugin (calico/canal/flannel/weave/cilium/contiv/kube-router)"
  default     = "calico"
}

variable "k8s_weave_encryption_password" {
  description = "Weave network encyption password "
  default     = ""
}

variable "k8s_dns_mode" {
  description = "Which DNS to use for the internal Kubernetes cluster name resolution (example: kubedns, coredns, etc.)"
  default     = "coredns"
}


variable "vm_user" {
  description = "SSH user for the vSphere virtual machines"
  default     = "root"
}


variable "vm_distro" {
  description = "Linux distribution of the vSphere virtual machines (ubuntu/centos/debian/rhel)"
  default     = "centos"
}