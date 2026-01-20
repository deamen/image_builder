##################################################################################
# SOURCE
##################################################################################
source "qemu" "alpine" {
  headless = "${var.headless}"

  iso_url      = "${local.alpine_iso_url}"
  iso_checksum = "${local.alpine_iso_checksum}"

  # Avoid conflicts when running multiple builds
  output_directory = "build/${var.vm_guest_os_name}${var.vm_guest_os_version}"
  # Use buildtime as indentifier
  vm_name            = "${var.vm_guest_os_name}${var.vm_guest_os_version}-qemu-tpl-${local.buildtime}.qcow2"
  accelerator        = "kvm"
  qemu_binary        = "${var.qemu_binary}"
  cpu_model          = "host"
  efi_boot           = true
  efi_firmware_code  = "${var.efi_firmware_code}"
  efi_firmware_vars  = "${var.efi_firmware_vars}"
  efi_drop_efivars   = true
  machine_type       = "${var.machine_type}"
  cpus               = "${var.vm_cpu_count}"
  memory             = "${var.vm_mem_size}"
  disk_size          = "${var.vm_disk_size}"
  disk_interface     = "virtio-scsi"
  disk_cache         = "unsafe"
  disk_discard       = "unmap"
  disk_detect_zeroes = "unmap"
  disk_compression   = true
  format             = "qcow2"
  net_device         = "virtio-net"
  vnc_bind_address   = "127.0.0.1"
  boot_wait          = "${var.vm_boot_wait}"
  boot_command       = local.boot_command_filtered
  shutdown_command   = "poweroff"
  http_content = {
    "/alpine_answerfile.cfg" = templatefile("files/alpine_answerfile.pkrtpl.cfg", { hostname = var.template_hostname, domain = var.domain, proxy_url = var.http_proxy })
  }
  ssh_username = "${var.build_username}"
  ssh_password = "${var.build_password}"
  ssh_timeout  = "${var.common_ip_wait_timeout}"

}

##################################################################################
# BUILD
##################################################################################

build {
  sources = ["source.qemu.alpine"]

  # Run the provision script
  provisioner "shell" {
    script = "files/provision.sh"
  }

  # Upload the default cloud.cfg
  provisioner "file" {
    source      = "files/cloud.cfg"
    destination = "/tmp/cloud.cfg"
  }

  # overwrite the default cloud.cfg
  provisioner "shell" {
    inline = [
      "mv /tmp/cloud.cfg /etc/cloud/cloud.cfg",
    ]
  }

  # Run the clean up script
  provisioner "shell" {
    script = "files/clean-image.sh"
  }

  post-processor "shell-local" {
    inline = ["mv build/${var.vm_guest_os_name}${var.vm_guest_os_version}/efivars.fd build/${var.vm_guest_os_name}${var.vm_guest_os_version}/${var.vm_guest_os_name}${var.vm_guest_os_version}-qemu-efivars-${local.buildtime}.fd"]
    only   = ["qemu.alpine"]
  }
}