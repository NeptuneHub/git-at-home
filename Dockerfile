FROM alpine:latest

# Install git, openssh, lighttpd for http access, and the passwd command
RUN apk add --no-cache git openssh shadow lighttpd

# Create git user, unlock the account, and setup directories
RUN adduser -D -s /bin/sh git && \
    # Unlock the account. Password will be set at runtime.
    passwd -d git && \
    # Create a default document root for lighttpd to satisfy its startup requirement.
    mkdir -p /home/git/.ssh /git/repos /var/log/lighttpd /var/www/localhost/htdocs && \
    chown -R git:git /home/git /git /var/log/lighttpd /var/www/localhost/htdocs && \
    chmod 700 /home/git/.ssh

# Enable Password Authentication for SSH
RUN sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# Configure lighttpd for git http backend using a standard, robust pattern.
# Using a heredoc for clarity and to avoid escaping issues with shell.
RUN cat <<EOF > /etc/lighttpd/lighttpd.conf
server.port = 80
server.username = "git"
server.groupname = "git"
server.document-root = "/var/www/localhost/htdocs"
server.errorlog = "/var/log/lighttpd/error.log"

# Load required modules
server.modules = (
    "mod_alias",
    "mod_cgi",
    "mod_setenv"
)

# Map the /git/ URL path to the git-http-backend CGI script
alias.url = ( "/git/" => "/usr/libexec/git-core/git-http-backend/" )

# For URLs under /git/, enable the CGI handler and set environment variables
\$HTTP["url"] =~ "^/git/" {
    cgi.assign = ( "" => "" )
    setenv.add-environment = (
        "GIT_PROJECT_ROOT" => "/git/repos",
        "GIT_HTTP_EXPORT_ALL" => ""
    )
}
EOF

# Expose SSH and HTTP ports
EXPOSE 22 80

# Copy the startup script that will manage the services
COPY start.sh /start.sh
RUN chmod +x /start.sh

# The CMD will run the startup script.
CMD ["/start.sh"]
