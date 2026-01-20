// Alpine Linux specific variables
locals {
  buildtime = formatdate("YYYYMMDDhhmmZZZ", timestamp())

  alpine_iso_url      = "https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-virt-3.23.2-x86_64.iso"
  alpine_iso_checksum = "c328a553ba9861e4ccb3560d69e426256955fa954bc6f084772e6e6cd5b0a4d0"

  # Read file, split into lines
  boot_command_lines = split("\n", trimspace(templatefile("files/boot_command.pkrtpl.txt", { build_password = var.build_password })))

  # Keep only lines that do NOT start with #
  boot_command_filtered = [for line in local.boot_command_lines : line if length(trimspace(line)) > 0 && length(regexall("^\\s*#", line)) == 0]
}
