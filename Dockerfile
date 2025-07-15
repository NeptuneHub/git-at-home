FROM alpine:latest

# Install git and openssh
RUN apk add --no-cache git openssh

# Create git user and setup directories
RUN adduser -D -s /bin/sh git && \
    mkdir -p /home/git/.ssh /git/repos && \
    chown -R git:git /home/git /git && \
    chmod 700 /home/git/.ssh

# Use git-shell to restrict shell access
RUN echo "/usr/libexec/git-core/git-shell" >> /etc/shells && \
    chsh -s /usr/libexec/git-core/git-shell git

# Expose SSH
EXPOSE 22

# Run SSH daemon
CMD ["/usr/sbin/sshd", "-D"]
