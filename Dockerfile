FROM alpine:latest

# Install git and openssh
RUN apk add --no-cache git openssh

# Create git user and setup directories
RUN adduser -D -s /bin/sh git && \
    mkdir -p /home/git/.ssh /git/repos && \
    chown -R git:git /home/git /git && \
    chmod 700 /home/git/.ssh

# Expose SSH
EXPOSE 22

# Run SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
