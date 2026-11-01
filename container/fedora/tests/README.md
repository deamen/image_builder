# Fedora container tests

This directory contains validation checks for the Fedora container image built by the project.

The Makefile is intentionally generic so it can run multiple test frameworks in the same directory, not only one tool.

## How the Makefile works

The Makefile automatically discovers test files by naming convention:

- `container-structure-test_*.yml` for container image validation using `container-structure-test`
- `test_*.py` for Python-based tests run with `pytest`

Each matching file becomes a target that can be run individually.

Examples:

- `make container-structure-test-fedora-init`
- `make pytest-something`

The aggregate target:

- `make tests`

runs all discovered test targets in this directory, against whatever single `IMAGE` is configured — so in practice you run one image's test file at a time.

## Running tests

From this directory:

```sh
make list-tests
make tests
```

To run a single test:

```sh
make container-structure-test-fedora-init IMAGE=quay.io/deamen/fedora-init-amd64:latest
make container-structure-test-fedora-ansible IMAGE=quay.io/deamen/fedora-ansible-amd64:latest
make container-structure-test-fedora-dst IMAGE=quay.io/deamen/fedora-dst-amd64:latest
```

If you add a new Python test file such as:

```sh
test_smoke.py
```

then it can be run with:

```sh
make pytest-smoke
```

## Configuration

The Makefile supports overriding the test tools and image name from the command line:

```sh
make tests CONTAINER_STRUCTURE_TEST=/usr/local/bin/container-structure-test
make tests PYTEST=python3 -m pytest
make tests IMAGE=quay.io/deamen/fedora-init-amd64:latest
```

## Pytest-based checks

`test_fedora-init.py` is an end-to-end usage test for `fedora-init`: it builds `Containerfile.sshd`
on top of the image under test (installing and enabling `sshd`), starts it as a container so
systemd actually boots, and uses [pytest-testinfra](https://testinfra.readthedocs.io/) (via its
`podman://` backend) to check that `sshd` is enabled, running, and listening on port 22.
`container-structure-test` alone can't do this since it doesn't boot the image.

Requires `pytest` and `pytest-testinfra` (`pip install pytest-testinfra`), plus `podman` on `PATH`.

```sh
make pytest-fedora-init IMAGE=quay.io/deamen/fedora-init-amd64:latest
```

## Notes

- `all` is aliased to `tests`.
- New test types can be added by following the same naming pattern and adding a matching rule to the Makefile.
