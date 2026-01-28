// Terraform provider and backend configuration
terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.9.1"
    }
  }

  backend "local" {
    path = "./terraform.tfstate"
  }
}

provider "libvirt" {
  # Use user session, RHEL 9 uses virtqemud-sock instead of libvirt-sock
  # uri = "qemu:///session?socket=/run/user/1000/libvirt/virtqemud-sock"
  # Use system session as will not need to manage pool and networks as non-root user
  #   only need to ensure user is in the libvirt group
  uri = "qemu:///system"
}

// variables
variable "domain" {
  type        = string
  description = "The domain of the vm"
  default     = "none"
}

variable "storage_pool" {
  description = "The storage pool name"
  type        = string
  default     = "default-pool"
}

variable "qemu_tpl" {
  description = "The QEMU template image URL"
  type        = string
  default     = "file:///path/to/qemu-alpine-template.qcow2"
}

variable "qemu_efivars" {
  description = "The QEMU EFI vars image URL"
  type        = string
  default     = "none"
}

variable "provisioner_username" {
  type        = string
  description = "The username to log into the vm."
  sensitive   = true
  default     = ""
}

variable "provisioner_password" {
  type        = string
  description = "The password to log into the vm."
  sensitive   = true
  default     = ""
}

variable "provisioner_password_hash" {
  type        = string
  description = "The password hash to log into the vm."
  sensitive   = true
  default     = ""
}

variable "efi_firmware_code" {
  type        = string
  description = " Path to the CODE part of OVMF."
  default     = "/usr/share/edk2/ovmf/OVMF_CODE.fd" # This is RHEL9
}

# resource "libvirt_pool" "default_pool" {
#   name = "default_pool"
#   type = "dir"
#   target = {
#       path = "/path/to/images"
#   }
# }

// VM
# Create the base image volume from the template
resource "libvirt_volume" "qemu_tpl_base" {
  name = "qemu_tpl_base.qcow2"
  pool = var.storage_pool
  target = {
    format = {
      type = "qcow2"
    }
  }

  create = {
    content = {
      url = var.qemu_tpl
    }
  }
}
