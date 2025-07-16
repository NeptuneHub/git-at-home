#!/bin/sh

# Exit immediately if a command exits with a non-zero status.
set -e

# Set git user password from the environment variable if it is provided.
if [ -n "$GIT_PASSWORD" ]; then
  echo "git:$GIT_PASSWORD" | chpasswd
fi

# Generate SSH host keys for the sshd service.
ssh-keygen -A

# Start lighttpd web server in the background to handle HTTP git requests.
/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf

# Start sshd in the foreground. This becomes the main process for the container.
exec /usr/sbin/sshd -D -e
