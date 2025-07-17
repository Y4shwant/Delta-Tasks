FROM ubuntu:22.04

# System essentials
RUN apt-get update && \
    apt-get install -y sudo acl bash tree cron wget nano curl python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

    RUN apt-get update && \
    apt-get install -y default-mysql-client

# Install Python dependencies
RUN pip3 install flask mysql-connector-python pyyaml

# Create groups and set permissions
RUN groupadd -g 5000 -r g_admin && \
    groupadd -g 5001 -r g_mod && \
    groupadd -g 5002 -r g_author && \
    groupadd -g 5003 -r g_user

# Copy server code and scripts
COPY /server/read_blog_api.py /usr/local/bin/read_blog_api.py
COPY users/scripts/* /usr/local/bin/
COPY /users/configs/*.yaml /configs/

# Install yq for YAML parsing in bash
RUN wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 && \
    chmod +x /usr/local/bin/yq

# Set permissions
RUN mkdir -p /defaults/etc && \
    cp -a /etc/* /defaults/etc/ && \
    touch /var/log/blog_activity.log && chmod 666 /var/log/blog_activity.log

# Set ownership and permissions for scripts
RUN chown root:g_admin /usr/local/bin/initusers.sh && chmod 750 /usr/local/bin/initusers.sh && \
    chown root:g_admin /usr/local/bin/sync_blogs.py && chmod 750 /usr/local/bin/sync_blogs.py && \
    chown root:g_admin /usr/local/bin/synx_users.py && chmod 750 /usr/local/bin/sync_users.py & \
    chown root:g_admin /usr/local/bin/UserFY.sh && chmod 750 /usr/local/bin/UserFY.sh && \
    chown root:g_mod /usr/local/bin/blogFilter.sh && chmod 750 /usr/local/bin/blogFilter.sh && \
    chown root:g_mod /usr/local/bin/update_blog_status.sh && chmod 750 /usr/local/bin/update_blog_status.sh && \
    chown root:g_author /usr/local/bin/manageBlogs.sh && chmod 750 /usr/local/bin/manageBlogs.sh && \
    chown root:g_user /usr/local/bin/read_blog.sh && chmod 750 /usr/local/bin/read_blog.sh

# Copy and make entrypoint executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /home

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
