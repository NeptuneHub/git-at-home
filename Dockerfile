FROM alpine:latest

# 1. INSTALL PACKAGES
# ===================================================================
# Install git for version control, openssh for SSH access, shadow for
# password management, nginx for the web server, and fcgi/spawn-fcgi
# to manage the CGI process.
# FIX: Added 'spawn-fcgi' package which provides the missing command.
RUN apk add --no-cache git openssh shadow nginx fcgi spawn-fcgi

# 2. CREATE USER AND DIRECTORIES
# ===================================================================
# Create a non-root user 'git' to own the repositories and manage services.
# Create all necessary directories for SSH, git repos, and Nginx.
RUN adduser -D -s /bin/sh git && \
    passwd -d git && \
    mkdir -p \
      /home/git/.ssh \
      /git/repos \
      /run/nginx && \
    chown -R git:git \
      /home/git \
      /git \
      /run/nginx && \
    chmod 700 /home/git/.ssh

# 3. CONFIGURE SSH
# ===================================================================
# Modify the SSH server configuration to explicitly allow password-based
# authentication, which is disabled by default in many images.
RUN sed -i 's/^#?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# 4. CONFIGURE HTTP (NGINX)
# ===================================================================
# Create a robust Nginx configuration for git-http-backend.
RUN cat <<EOF > /etc/nginx/nginx.conf
# Run nginx worker processes as the 'git' user
user git git;
worker_processes 1;
pid /run/nginx/nginx.pid;

events {
    worker_connections 1024;
}

http {
    server {
        listen 80;
        server_name localhost;

        # This location block handles all incoming requests
        location / {
            # Pass all requests to the fcgiwrap socket where the git script is listening
            fastcgi_pass unix:/var/run/fcgiwrap.socket;

            # Set required FastCGI parameters for the git backend script
            include fastcgi_params;
            param SCRIPT_FILENAME   /usr/libexec/git-core/git-http-backend;
            param GIT_PROJECT_ROOT  /git/repos;
            param GIT_HTTP_EXPORT_ALL "";
            param PATH_INFO         \$request_uri;
        }
    }
}
EOF

# 5. EXPOSE PORTS AND DEFINE STARTUP COMMAND
# ===================================================================
EXPOSE 22 80
COPY start.sh /start.sh
RUN chmod +x /start.sh
CMD ["/start.sh"]
