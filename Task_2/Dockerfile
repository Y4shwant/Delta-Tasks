FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y sudo acl yq bash tree && \
    rm -rf /var/lib/apt/lists/*

# Create groups
RUN groupadd -r g_user && \
    groupadd -r g_author && \
    groupadd -r g_mod && \
    groupadd -r g_admin

# Create admin user for default access
RUN useradd -m -s /bin/bash mukundk && usermod -aG g_admin mukundk

# Copy scripts
COPY scripts/*.sh /usr/local/bin/
COPY scripts/scripts-sudoers /etc/sudoers.d/scripts

# Ensure sudoers config is secure
RUN chmod 440 /etc/sudoers.d/scripts && chown root:root /etc/sudoers.d/scripts

# Make all scripts executable and group-specific
RUN chmod 755 /usr/local/bin/*.sh && \
    chown root:g_author /usr/local/bin/manageBlogs.sh && chmod 750 /usr/local/bin/manageBlogs.sh && \
    chown root:g_admin /usr/local/bin/initusers.sh /usr/local/bin/UserFY.sh /usr/local/bin/adminPanel.sh /usr/local/bin/dummy_blogs.sh /usr/local/bin/delete_dummies.sh && \
    chmod 750 /usr/local/bin/initusers.sh /usr/local/bin/UserFY.sh /usr/local/bin/adminPanel.sh /usr/local/bin/dummy_blogs.sh /usr/local/bin/delete_dummies.sh && \
    chown root:g_mod /usr/local/bin/blogFilter.sh /usr/local/bin/update_blog_status.sh /usr/local/bin/fix_blog_owner.sh && \
    chmod 750 /usr/local/bin/blogFilter.sh /usr/local/bin/update_blog_status.sh /usr/local/bin/fix_blog_owner.sh && \
    chown root:g_user /usr/local/bin/read_blog.sh && chmod 750 /usr/local/bin/read_blog.sh

# Create persistent log file
RUN touch /var/log/blog_activity.log && \
    chown root:g_admin /var/log/blog_activity.log && \
    setfacl -m g:g_author:-w- /var/log/blog_activity.log && \
    setfacl -m group::rwx /var/log/blog_activity.log

WORKDIR /home
CMD ["/bin/bash"]

