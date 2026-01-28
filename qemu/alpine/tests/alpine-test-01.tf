# Reference for 0.9.1 https://github.com/dmacvicar/terraform-provider-libvirt/issues/1243#issuecomment-3733594009

data "template_file" "alpine-test-01_cloud_init_user_data" {
  template = file("${path.module}/files/cloud_init.cfg.tpl")
  vars = {
    fqdn                      = "alpine-test-01.${var.domain}"
    provisioner_password_hash = var.provisioner_password_hash
  }
}

resource "libvirt_cloudinit_disk" "alpine-test-01_cloudinit" {
  name      = "alpine-test-01_cloudinit"
  user_data = data.template_file.alpine-test-01_cloud_init_user_data.rendered
  meta_data = yamlencode({
    instance-id    = "alpine-test-01"
    local-hostname = "alpine-test-01.${var.domain}"
  })
}

resource "libvirt_volume" "alpine-test-01_cloudinit_iso" {
  name = "alpine-test-01_cloudinit.iso"
  pool = "${var.storage_pool}"

  create = {
    content = {
      url = libvirt_cloudinit_disk.alpine-test-01_cloudinit.path
    }
  }
}


resource "libvirt_volume" "alpine-test-01_os" {
  name = "alpine-test-01_os.qcow2"
  pool = var.storage_pool

  target = {
    format = {
      type = "qcow2"
    }
  }

  capacity = 8 * 1024 * 1024 * 1024 // 8 GB

  backing_store = {
    path = libvirt_volume.qemu_tpl_base.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_domain" "alpine-test-01" {
  name        = "alpine-test-01"
  memory      = "1024"
  memory_unit = "MiB"
  vcpu        = 4
  type        = "kvm"
  autostart   = true
  running     = true

  os = {
    type         = "hvm"
    type_arch    = "x86_64"
    type_machine = "q35"
    firmware     = "efi"
    loader       = "${var.efi_firmware_code}"
  }
  features = {
    acpi = true
    apic = {
      eoi = "on"
    }
    smm = {
      state = "on"
    }
    vm_port = {
      state = "off"
    }
  }

  cpu = {
    mode = "host-passthrough"
  }

  devices = {
    disks = [

      {
        driver = {
          name    = "qemu"
          type    = "qcow2"
          discard = "unmap"
        }
        source = {
          volume = {
            pool   = libvirt_volume.alpine-test-01_os.pool
            volume = libvirt_volume.alpine-test-01_os.name
          }
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      },
      {
        device = "cdrom"
        driver = {
          name = "qemu"
          type = "raw"
        }
        source = {
          volume = {
            pool   = libvirt_volume.alpine-test-01_cloudinit_iso.pool
            volume = libvirt_volume.alpine-test-01_cloudinit_iso.name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      }
    ]
    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          network = {
            network = "default"
          }
        }
        wait_for_ip = {
          source = "agent"
        }
      }
    ]

    graphics = [
      {
        vnc = {
          autoport = "yes"
          listen   = "127.0.0.1"
        }
      }
    ]
    consoles = [
      {
        type = "pty"
        target = {
          type = "serial"
        }
      }
    ]

    channels = [
      {
        source = {
          unix = {
            mode = "bind"
          }
        }
        target = {
          type = "virtio"
          virt_io = {
            name = "org.qemu.guest_agent.0"
          }
        }
    }]
  }
}

data "libvirt_domain_interface_addresses" "alpine-test-01_interfaces" {
  domain = libvirt_domain.alpine-test-01.name
  source = "agent"
  depends_on = [
    libvirt_domain.alpine-test-01,
  ]
}

output "alpine-test-01_ip_addr" {
  description = "All IP addresses reported for the VM"
  value = [
    for iface in data.libvirt_domain_interface_addresses.alpine-test-01_interfaces.interfaces :
    [for a in iface.addrs : a.addr]
  ][1][0]
  depends_on = [
    libvirt_domain.alpine-test-01,
    data.libvirt_domain_interface_addresses.alpine-test-01_interfaces
  ]
}

output "alpine-test-01_mac_addr" {
  description = "MAC address for each interface (order matches `ip_addr` list)"
  value = [
    for iface in data.libvirt_domain_interface_addresses.alpine-test-01_interfaces.interfaces :
    iface.hwaddr
  ][1]
  depends_on = [
    libvirt_domain.alpine-test-01,
    data.libvirt_domain_interface_addresses.alpine-test-01_interfaces
  ]
}
