#!/usr/bin/bash
# ------------------------------------------------------------
# Script to manage a .testinfra_py_venv virtual environment
# Features:
#   • Exits on any error (set -e)
#   • Creates the venv only if it does not already exist
#   • Provides a “--clean” (or -c) flag to delete the existing venv
# ------------------------------------------------------------

set -e
usage() {
    echo "Usage: $(basename "$0") [--clean|-c]"
    echo ""
    echo "Options:"
    echo "  --clean, -c   Delete the existing .testinfra_py_venv folder before proceeding"
    echo "  -h, --help    Show this help message"
    exit 1
}
CLEAN=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean|-c) CLEAN=true ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_PATH="${SCRIPT_DIR}/.testinfra_py_venv"
if $CLEAN && [[ -d "$VENV_PATH" ]]; then
    echo "Removing existing virtual environment at $VENV_PATH ..."
    rm -rf "$VENV_PATH"
fi

if [[ ! -d "$VENV_PATH" ]]; then
    echo "Creating virtual environment at $VENV_PATH ..."
    python3 -m venv "$VENV_PATH"
    source "${VENV_PATH}/bin/activate"
    echo "Installing testinfra ..."
    pip install --upgrade pip
    pip install testinfra
    echo "Setup complete. Virtual environment is ready at $VENV_PATH."
else
    echo "Virtual environment already exists at $VENV_PATH – nothing to do."
fi
