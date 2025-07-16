FROM alpine:latest

# Install git, openssh, lighttpd for http access, and the passwd command
RUN apk add --no-cache git openssh shadow lighttpd

# Create git user, unlock the account, and setup directories
RUN adduser -D -s /bin/sh git && \
    # Unlock the account. Password will be set at runtime.
    passwd -d git && \
    # FIX: Create a default document root for lighttpd to satisfy its startup requirement.
    mkdir -p /home/git/.ssh /git/repos /var/log/lighttpd /var/www/localhost/htdocs && \
    chown -R git:git /home/git /git /var/log/lighttpd /var/www/localhost/htdocs && \
    chmod 700 /home/git/.ssh

# Enable Password Authentication for SSH
RUN sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Configure lighttpd for git http backend
# Run lighttpd as the 'git' user and group to ensure it has permissions
# to read the repository files.
RUN echo 'server.port = 80' > /etc/lighttpd/lighttpd.conf && \
    echo 'server.username = "git"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'server.groupname = "git"' >> /etc/lighttpd/lighttpd.conf && \
    # FIX: Set a default document-root. This is required for lighttpd to start,
    # but it won't interfere with the git CGI script.
    echo 'server.document-root = "/var/www/localhost/htdocs"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'server.modules = ( "mod_cgi", "mod_setenv" )' >> /etc/lighttpd/lighttpd.conf && \
    echo 'server.errorlog = "/var/log/lighttpd/error.log"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'setenv.add-environment = ( "GIT_PROJECT_ROOT" => "/git/repos", "GIT_HTTP_EXPORT_ALL" => "" )' >> /etc/lighttpd/lighttpd.conf && \
    echo 'cgi.assign = ( "" => "/usr/libexec/git-core/git-http-backend" )' >> /etc/lighttpd/lighttpd.conf

# Expose SSH and HTTP ports
EXPOSE 22 80

# Copy the startup script that will manage the services
COPY start.sh /start.sh
RUN chmod +x /start.sh

# The CMD will run the startup script.
CMD ["/start.sh"]
