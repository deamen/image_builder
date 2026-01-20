// QEMU Builder specific variables
variable "headless" {
  type        = bool
  description = "Packer defaults to building QEMU virtual machines by launching a GUI that shows the console of the machine being built. When this value is set to true, the machine will start without a console. You can still see the console if you make a note of the VNC display number chosen, and then connect using vncviewer -Shared <host>:<display>"
  default     = true
}

variable "qemu_binary" {
  type        = string
  description = "The name of the Qemu binary to look for. This defaults to qemu-system-x86_64, but may need to be changed for some platforms."
  default     = "/usr/libexec/qemu-kvm" # This is RHEL9
}

variable "efi_firmware_code" {
  type        = string
  description = " Path to the CODE part of OVMF."
  default     = "/usr/share/OVMF/OVMF_CODE.secboot.fd" # This is RHEL9
}

variable "efi_firmware_vars" {
  type        = string
  description = "TPath to the VARS corresponding to the OVMF code file."
  default     = "/usr/share/OVMF/OVMF_VARS.secboot.fd" # This is RHEL9
}

variable "machine_type" {
  type        = string
  description = "The type of machine to emulate."
  default     = "pc-q35-rhel9.6.0" # This has to be pc-q35 for efi
}