FROM alpine:latest

# 1. INSTALL PACKAGES
# ===================================================================
# Install git for version control, openssh for SSH access, shadow for
# password management, and lighttpd for the web server.
RUN apk add --no-cache git openssh shadow lighttpd

# 2. CREATE USER AND DIRECTORIES
# ===================================================================
# Create a non-root user 'git' to own the repositories and manage services.
# Create all necessary directories for SSH, git repos, logs, and a dummy
# web root required by the web server to start.
RUN adduser -D -s /bin/sh git && \
    passwd -d git && \
    mkdir -p \
      /home/git/.ssh \
      /git/repos \
      /var/log/lighttpd \
      /var/www/localhost/htdocs && \
    chown -R git:git \
      /home/git \
      /git \
      /var/log/lighttpd \
      /var/www/localhost/htdocs && \
    chmod 700 /home/git/.ssh

# 3. CONFIGURE SSH
# ===================================================================
# Modify the SSH server configuration to explicitly allow password-based
# authentication, which is disabled by default in many images.
RUN sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 4. CONFIGURE HTTP (WEB SERVER)
# ===================================================================
# Create a minimal, robust configuration for lighttpd.
# This setup dedicates the entire web server to handling git requests.
RUN cat <<EOF > /etc/lighttpd/lighttpd.conf
# Run the server on the standard HTTP port.
server.port = 80

# Run the process as the 'git' user and group to ensure it has
# permissions to read the git repositories.
server.username = "git"
server.groupname = "git"

# Set a dummy document root. This is required for lighttpd to start
# but does not interfere with the git service.
server.document-root = "/var/www/localhost/htdocs"

# Log errors to a file that the 'git' user has permission to write to.
server.errorlog = "/var/log/lighttpd/error.log"

# Load only the modules required for the git CGI script.
server.modules = ( "mod_cgi", "mod_setenv" )

# Set environment variables required by the git-http-backend script.
# - GIT_PROJECT_ROOT tells git where to find the repositories.
# - GIT_HTTP_EXPORT_ALL allows cloning of all repositories without needing
#   a special 'git-daemon-export-ok' file.
setenv.add-environment = (
    "GIT_PROJECT_ROOT" => "/git/repos",
    "GIT_HTTP_EXPORT_ALL" => ""
)

# Assign all incoming requests to be handled by the git CGI script.
# This is the simplest and most reliable setup for a dedicated git server.
cgi.assign = ( "" => "/usr/libexec/git-core/git-http-backend" )
EOF

# 5. EXPOSE PORTS AND DEFINE STARTUP COMMAND
# ===================================================================
EXPOSE 22 80
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
