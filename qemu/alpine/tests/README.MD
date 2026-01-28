# Test Alpine QEMU Image
Test the Alpine QEMU image with Terraform and the libvirt provider.

Requires:
1. Packages: pwgen, mkpasswd
2. A pre-defined system storage pool
3. The user running the tests needs to be in the `libvirt` group.
```
make destroy
make tests
```
