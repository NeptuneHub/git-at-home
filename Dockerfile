FROM alpine:latest

# Install git, openssh, lighttpd for http access, and the passwd command
RUN apk add --no-cache git openssh shadow lighttpd

# Create git user, unlock the account, and setup directories
RUN adduser -D -s /bin/sh git && \
    # Unlock the account. Password will be set at runtime.
    passwd -d git && \
    mkdir -p /home/git/.ssh /git/repos && \
    chown -R git:git /home/git /git && \
    chmod 700 /home/git/.ssh

# --- FIX: Enable Password Authentication for SSH ---
# Find the line for PasswordAuthentication in the sshd_config file,
# uncomment it if necessary, and set its value to "yes".
RUN sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Configure lighttpd for git http backend
RUN echo 'server.port = 80' > /etc/lighttpd/lighttpd.conf && \
    echo 'server.document-root = "/git/repos"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'server.modules = ( "mod_cgi", "mod_setenv" )' >> /etc/lighttpd/lighttpd.conf && \
    echo 'server.errorlog = "/dev/stderr"' >> /etc/lighttpd/lighttpd.conf && \
    echo 'setenv.add-environment = ( "GIT_PROJECT_ROOT" => "/git/repos", "GIT_HTTP_EXPORT_ALL" => "" )' >> /etc/lighttpd/lighttpd.conf && \
    echo 'cgi.assign = ( "" => "/usr/libexec/git-core/git-http-backend" )' >> /etc/lighttpd/lighttpd.conf

# Expose SSH and HTTP ports
EXPOSE 22 80

# Copy the startup script that will manage the services
COPY start.sh /start.sh
RUN chmod +x /start.sh

# The CMD will run the startup script.
# The script is responsible for setting the password and starting services.
CMD ["/start.sh"]
