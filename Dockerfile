FROM alpine:latest

# Install git, openssh, and the passwd command
RUN apk add --no-cache git openssh shadow

# Create git user, unlock the account, and setup directories
RUN adduser -D -s /bin/sh git && \
    # FIX: Delete the user's password to unlock the account for key-based auth
    passwd -d git && \
    mkdir -p /home/git/.ssh /git/repos && \
    chown -R git:git /home/git /git && \
    chmod 700 /home/git/.ssh

# Expose SSH port
EXPOSE 22

# FIX: Generate host keys on startup and run the SSH daemon
# This ensures host keys exist but are not part of the image layer.
CMD ssh-keygen -A && exec /usr/sbin/sshd -D -e
