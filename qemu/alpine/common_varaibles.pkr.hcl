// Variables that are common between different builder/hypervisor

// Ansible Credentials
variable "ansible_username" {
  type        = string
  description = "The username for Ansible to login to the guest operating system."
  default     = "ansible.svc"
}

// Communicator Settings and Credentials

variable "build_username" {
  type        = string
  description = "The username to login to the guest operating system when building the image."
  sensitive   = true
  default     = ""
}

variable "build_password" {
  type        = string
  description = "The password to login to the guest operating system when building the image, this should be changed during provisioning."
  sensitive   = true
  default     = ""
}

variable "build_password_hash" {
  type        = string
  description = "The password hash to login to the guest operating system when building the image, this should be changed during provisioning."
  sensitive   = true
  default     = ""
}

// Virtual Machine Settings
variable "vm_guest_os_name" {
  type        = string
  description = "The guest operating system name. Used for naming."
}

variable "vm_guest_os_version" {
  type        = string
  description = "The guest operating system version. Used for naming."
}
variable "vm_cpu_count" {
  type        = number
  description = "The number of virtual CPUs."
  default     = 2
}

variable "vm_disk_size" {
  type        = number
  description = "The size for the virtual disk in MB."
  default     = 40960
}

variable "vm_mem_size" {
  type        = number
  description = "The size for the virtual memory in MB."
  default     = 2048
}

// Boot Settings
variable "common_ip_wait_timeout" {
  type        = string
  description = "Time to wait for guest operating system IP address response."
  default     = "20m"
}

variable "vm_boot_wait" {
  type        = string
  description = "The time to wait before boot."
  default     = "10s"
}

// proxy settings
variable "http_proxy" {
  type        = string
  description = "The proxy for http"
  default     = "none"
}

variable "https_proxy" {
  type        = string
  description = "The proxy for https"
  default     = "none"
}

variable "ftp_proxy" {
  type        = string
  description = "The proxy for ftp"
  default     = "none"
}

// MISC
variable "template_hostname" {
  type        = string
  description = "The hostname of the vm template"
  default     = "none"
}

variable "domain" {
  type        = string
  description = "The domain of the vm template, $${template_hostname}.$${domain} is the FQDN of the vm template"
  default     = "none"
}