#cloud-config
# vim: syntax=yaml
#
# ***********************
# 	---- for more examples look at: ------
# ---> https://cloudinit.readthedocs.io/en/latest/topics/examples.html
# ******************************

chpasswd:
  expire: false
  users:
    - name: ansible.svc
      password: ${provisioner_password_hash}

timezone: Australia/Melbourne

prefer_fqdn_over_hostname: true
fqdn: ${fqdn}

manage_etc_hosts: true

###
# Disalbe ssh key automatic generation
# The process starts before the new FQDN is set,
# ends up using the template hostname.
# Use ssh-keygen and restart sshd to generate the keys later.
# This will generate a schema validation warning, ignore it.
###
ssh_deletekeys: true
ssh_genkeytypes: []

runcmd:
  - ssh-keygen -A
  - rc-service sshd restart

write_files:
  - path: /etc/doas.d/20-wheel.conf
    owner: root:root
    permissions: '0644'
    content: |
      permit persist :wheel
