"""
End-to-end test for fedora-init: builds Containerfile.sshd on top of the image
under test, starts it as a systemd container, and checks sshd comes up.
"""

import os
import subprocess
import time
import uuid
from pathlib import Path

import pytest
import testinfra

TESTS_DIR = Path(__file__).parent
SSHD_CONTAINERFILE = TESTS_DIR / "Containerfile.sshd"
BASE_IMAGE = os.environ.get("IMAGE", "quay.io/deamen/fedora-init-amd64:latest")
STARTUP_TIMEOUT_SECONDS = 30


def _podman(*args, check=True):
    return subprocess.run(["podman", *args], check=check)


@pytest.fixture(scope="module")
def sshd_container():
    suffix = uuid.uuid4().hex[:8]
    test_image = f"localhost/fedora-init-sshd-test:{suffix}"
    container_name = f"fedora-init-sshd-test-{suffix}"

    _podman(
        "build",
        "-f",
        str(SSHD_CONTAINERFILE),
        "--build-arg",
        f"BASE_IMAGE={BASE_IMAGE}",
        "-t",
        test_image,
        str(TESTS_DIR),
    )
    _podman("run", "-d", "--name", container_name, test_image)

    try:
        yield container_name
    finally:
        _podman("rm", "-f", container_name, check=False)
        _podman("rmi", "-f", test_image, check=False)


@pytest.fixture(scope="module")
def host(sshd_container):
    return testinfra.get_host(f"podman://{sshd_container}")


@pytest.fixture(scope="module")
def running_sshd_service(host):
    # systemd needs a moment to boot before sshd is active, so poll rather
    # than assume it's up right after `podman run` returns.
    service = host.service("sshd")
    deadline = time.monotonic() + STARTUP_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        if service.is_running:
            return service
        time.sleep(1)
    pytest.fail(f"sshd did not become active within {STARTUP_TIMEOUT_SECONDS}s")


def test_sshd_is_enabled(host):
    assert host.service("sshd").is_enabled


def test_sshd_is_running(running_sshd_service):
    assert running_sshd_service.is_running


def test_sshd_is_listening(running_sshd_service, host):
    assert host.socket("tcp://0.0.0.0:22").is_listening
