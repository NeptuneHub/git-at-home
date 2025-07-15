FROM alpine:latest

# Install git and openssh (no cache to keep image small)
RUN apk add --no-cache git openssh

# Create 'git' user with home directory
RUN adduser -D -s /bin/sh git && \
    mkdir -p /home/git/.ssh /git/repos && \
    chown -R git:git /home/git /git && \
    chmod 700 /home/git/.ssh

# Restrict shell to git-shell (no interactive login)
RUN which git-shell && \
    echo "/usr/bin/git-shell" >> /etc/shells && \
    chsh -s /usr/bin/git-shell git

# Expose SSH port
EXPOSE 22

# Run SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
