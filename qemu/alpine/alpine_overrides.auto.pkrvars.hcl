// Alpine Linux specific overrides
// Override the default value defined in common_variables.pkr.hcl

vm_guest_os_name    = "alpine"
vm_guest_os_version = "3.23"
# Alpine ISO will not boot when secure-boot is enabled
# Wait until all the boot media has been tried
vm_boot_wait = "280s"
vm_disk_size = "4096"
###
# We use root user for building alpine images,
# because doas is not available in the default alpine installation.
# The root credentials used for building the image are temprorary,
# and should be changed during provisioning.
###
build_username    = "root"
template_hostname = "alpine-tpl"
