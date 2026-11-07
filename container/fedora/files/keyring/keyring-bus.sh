# Point CLI tools at the session bus started by keyring-unlock, once it is running.
if [ -S "/run/user/$(id -u)/bus" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi
