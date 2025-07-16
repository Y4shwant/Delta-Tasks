#!/bin/bash
echo "[*] Running entrypoint for persistence glue..."

# Check if /etc is empty (first-time run)
if [ -z "$(ls -A /etc 2>/dev/null | grep -v 'lost+found')" ]; then
    echo "[*] /etc is empty. Seeding from /defaults/etc..."
    cp -a /defaults/etc/* /etc/

    # Add sudoers rules during first-time seeding
    if [ ! -f /etc/sudoers.d/blogserver ]; then
        echo "[*] Adding sudoers rules for blogserver (first-time)..."
        cat << 'EOF' > /etc/sudoers.d/blogserver
%g_mod ALL=(ALL) NOPASSWD: /usr/local/bin/update_blog_status.sh
%g_mod ALL=(ALL) NOPASSWD: /usr/local/bin/fix_blog_owner.sh
%g_user ALL=(ALL) NOPASSWD: /usr/local/bin/read_blog.sh
%g_admin ALL=(ALL) NOPASSWD: /usr/local/bin/*
EOF
        chmod 440 /etc/sudoers.d/blogserver
    fi

else
    echo "[*] /etc already populated. Skipping seeding."

    # Check if sudoers rules exist
    if [ ! -f /etc/sudoers.d/blogserver ]; then
        echo "[*] Adding missing sudoers rules for blogserver..."
        cat << 'EOF' > /etc/sudoers.d/blogserver
%g_mod ALL=(ALL) NOPASSWD: /usr/local/bin/update_blog_status.sh
%g_mod ALL=(ALL) NOPASSWD: /usr/local/bin/fix_blog_owner.sh
%g_user ALL=(ALL) NOPASSWD: /usr/local/bin/read_blog.sh
%g_admin ALL=(ALL) NOPASSWD: /usr/local/bin/*
www-data ALL=(ALL) NOPASSWD: /usr/local/bin/read_blog.sh

EOF
        chmod 440 /etc/sudoers.d/blogserver
    else
        echo "[*] Sudoers rules for blogserver already present. Skipping."
    fi
fi

# Debug: Show /etc contents
echo "[*] Current /etc directory:"
ls -A /etc

# Debug: Show sudoers.d content
echo "[*] /etc/sudoers.d/blogserver contents:"
cat /etc/sudoers.d/blogserver 2>/dev/null || echo "[!] No blogserver sudoers file found"
exec python3 /usr/local/bin/read_blog_api.py