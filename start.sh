#!/bin/sh

# Exit on any error
set -e

# 1. Set password for git user from environment variable
if [ -n "$GIT_PASSWORD" ]; then
  echo "git:$GIT_PASSWORD" | chpasswd
fi

# 2. Generate SSH host keys if they don't exist
ssh-keygen -A

# 3. Start the SSH daemon in the background
/usr/sbin/sshd

# 4. Start the FastCGI wrapper daemon in the background.
# It will listen on a unix socket for requests from Nginx.
spawn-fcgi -s /var/run/fcgiwrap.socket -U git -G git /usr/bin/fcgiwrap

# 5. Start Nginx in the foreground.
# This will be the main process for the container. If it exits, the container stops.
exec /usr/sbin/nginx -g 'daemon off;'
