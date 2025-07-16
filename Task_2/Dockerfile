FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Update and install required packages
RUN apt-get update && \
    apt-get install -y sudo acl bash tree cron wget nano curl && \
    rm -rf /var/lib/apt/lists/*

# Create user groups
RUN groupadd -g 5000 -r g_admin && \
    groupadd -g 5001 -r g_mod && \
    groupadd -g 5002 -r g_author && \
    groupadd -g 5003 -r g_user

# Install yq (Mike Farah official binary)
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Copy admin/mod/user scripts into container
COPY users/scripts/*.sh /usr/local/bin/

COPY /users/configs/*.yaml /configs/
# Seed /etc into /defaults/etc for first-time volume init
RUN mkdir -p /defaults/etc && \
    cp -a /etc/* /defaults/etc/ && \
    touch /var/log/blog_activity.log && \
    chmod 666 /var/log/blog_activity.log


# Set permissions for scripts
# Admin scripts: g_admin group, 710
RUN chown root:g_admin /usr/local/bin/initusers.sh && chmod 750 /usr/local/bin/initusers.sh && \
    chown root:g_admin /usr/local/bin/UserFY.sh && chmod 750 /usr/local/bin/UserFY.sh && \
    chown root:g_admin /usr/local/bin/adminPanel.sh && chmod 750 /usr/local/bin/adminPanel.sh && \
    chown root:g_admin /usr/local/bin/dummy_blogs.sh && chmod 750 /usr/local/bin/dummy_blogs.sh && \
    chown root:g_admin /usr/local/bin/delete_dummies.sh && chmod 750 /usr/local/bin/delete_dummies.sh

# Mod scripts: g_mod group, 750
RUN chown root:g_mod /usr/local/bin/blogFilter.sh && chmod 750 /usr/local/bin/blogFilter.sh && \
    chown root:g_mod /usr/local/bin/update_blog_status.sh && chmod 750 /usr/local/bin/update_blog_status.sh && \
    chown root:g_mod /usr/local/bin/fix_blog_owner.sh && chmod 750 /usr/local/bin/fix_blog_owner.sh

# Author script: g_author group, 750
RUN chown root:g_author /usr/local/bin/manageBlogs.sh && chmod 750 /usr/local/bin/manageBlogs.sh

# User script: g_user group, 750
RUN chown root:g_user /usr/local/bin/read_blog.sh && chmod 750 /usr/local/bin/read_blog.sh

# Copy entrypoint.sh
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set working directory
WORKDIR /home

# Set entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD ["/bin/bash"]
