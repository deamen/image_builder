import pytest


service_accounts_to_test = {"ansible.svc": "wheel"}


@pytest.mark.parametrize("service_account, group", service_accounts_to_test.items())
def test_service_accounts(host, service_account, group):
    """Check if the service accounts are created and added to the correct group"""
    assert host.user(service_account).exists
    assert host.group(group).exists
    assert service_account in host.user(service_account).groups


def test_wheel_group_doas_file(host):
    """Check if wheel group doas file is present and correct"""
    sudoers_file = host.file("/etc/doas.d/20-wheel.conf")
    sudoers_file.contains("permit persist :wheel")


def test_kvm_guest_tools_installed(host):
    """Check if Hypervisor Guest Additions/Tools/Agents/Kernel modules installed"""
    kvm_tools = ["qemu-guest-agent", "rsync", "nfs-utils"]
    for package in kvm_tools:
        assert host.package(package).is_installed


def test_kvm_guest_services_are_running(host):
    """Check if guest agents services running and enabled"""
    assert host.service("qemu-guest-agent.service").is_running
    assert host.service("qemu-guest-agent.service").is_enabled


###
# SSH Host private keys require doas/sudo privileges to read,
# and we do not allow passwordless sudo, therefore it is not possible with Testinfra.
# Since public/private key pairs with each other, testing the public keys only should be enough.
###
@pytest.mark.dependency(name="test_get_ssh_host_pub_keys")
def test_get_ssh_host_pub_keys(host):
    """Get checksum of SSH host public keys from each machine and write to file"""
    hostname = host.check_output("hostname")
    with host.sudo():
        host_key = host.check_output("sha256sum /etc/ssh/ssh_host_*_key.pub")
    with open(f"{hostname}.sshhostkeys", "w") as fd:
        fd.write(host_key)


@pytest.mark.dependency(depends=["test_get_ssh_host_pub_keys"])
def test_uniqueness_of_ssh_host_pub_keys(host):
    """Check if SSH host public keys are unique for each machine"""
    hostname = host.check_output("hostname")
    if hostname == "alpine-test-1":
        with open("alpine-test-1.sshhostkeys", "r") as file:
            ssh_host_pub_keys_a = file.read()
        with open("alpine-test-2.sshhostkeys", "r") as file:
            ssh_host_pub_keys_b = file.read()
        assert ssh_host_pub_keys_a != ssh_host_pub_keys_b
