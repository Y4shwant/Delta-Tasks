#!/bin/bash
set -e

YAML_FILE="/configs/sysad-1-users.yaml"

# Capture previous user sets
PREV_USERS=$(getent passwd | awk -F: '/\/home\/users\// {print $1}')
PREV_AUTHORS=$(getent passwd | awk -F: '/\/home\/authors\// {print $1}')
PREV_MODS=$(getent passwd | awk -F: '/\/home\/mods\// {print $1}')

echo "Creating groups..."
for group in g_user g_author g_mod g_admin; do
    if ! getent group "$group" > /dev/null; then
        groupadd "$group"
        echo " Group created: $group"
    fi
done

create_user() {
    local username="$1"
    local group="$2"
    local homedir="$3"

    if id "$username" &>/dev/null; then
        echo "User $username already exists, skipping creation."
    else
        useradd -m -d "$homedir/$username" -g "$group" "$username"
        echo "Created user $username in group $group with home $homedir/$username"
        mkdir -p "$homedir/$username"
        chown -R "$username:$group" "$homedir/$username"
    fi
}

echo "Creating Admins..."
ADMINS=$(yq '.admins[].username' "$YAML_FILE")
for username in $ADMINS; do
    create_user "$username" g_admin "/home/admins"
done

echo "Creating Authors..."
AUTHORS=$(yq '.authors[].username' "$YAML_FILE")
for username in $AUTHORS; do
    create_user "$username" g_author "/home/authors"
    mkdir -p "/home/authors/$username/blogs" "/home/authors/$username/public"

    yaml_file="/home/authors/$username/blogs.yaml"
    if [ ! -f "$yaml_file" ]; then
        cat <<EOF > "$yaml_file"
categories:
  1: "Sports"
  2: "Cinema"
  3: "Technology"
  4: "Travel"
  5: "Food"
  6: "Lifestyle"
  7: "Finance"

blogs: []
EOF
        chown "$username:g_author" "$yaml_file"
        chmod 644 "$yaml_file"
        echo "Initialized blogs.yaml for $username"
    fi
done

echo "Creating Moderators..."
MODS=$(yq '.mods[].username' "$YAML_FILE")
for username in $MODS; do
    create_user "$username" g_mod "/home/mods"
done

echo "Creating Users..."
USERS=$(yq '.users[].username' "$YAML_FILE")
for username in $USERS; do
    create_user "$username" g_user "/home/users"
done

# User and author perms
for user in $USERS; do chmod 700 "/home/users/$user"; done
for author in $AUTHORS; do
    chmod 700 "/home/authors/$author"
    setfacl -b "/home/authors/$author/blogs"
    chmod 711 "/home/authors/$author/blogs"
    
done

echo "Assigning moderator ACLs and links..."
for mod in $MODS; do
    authors=$(yq ".mods[] | select(.username == \"$mod\") | .authors[]" "$YAML_FILE")

    # blacklist.txt
    touch "/home/mods/$mod/blacklist.txt"
    chown "$mod:g_admin" "/home/mods/$mod/blacklist.txt"
    chmod 770 "/home/mods/$mod/blacklist.txt"
    echo "# please write one word per line" > "/home/mods/$mod/blacklist.txt"

    for dir in /home/authors/*/public; do
        setfacl -x u:$mod "$dir" 2>/dev/null || true
    done

    for author in $authors; do
        setfacl -m u:$mod:x "/home/authors/$author"
        setfacl -m u:$mod:rwx "/home/authors/$author/public"
        setfacl -m u:$mod:rwx "/home/authors/$author/blogs"
        setfacl -d -m u:$mod:rwx "/home/authors/$author/public"
        setfacl -d -m u:$mod:rwx "/home/authors/$author/blogs"
        setfacl -d -m m::rwx "/home/authors/$author/public"
        setfacl -d -m m::rwx "/home/authors/$author/blogs"
    done

    mkdir -p "/home/mods/$mod/authors_public"
    for author in $authors; do
        link="/home/mods/$mod/authors_public/$author"
        target="/home/authors/$author/public"
        if [ ! -L "$link" ]; then
            ln -s "$target" "$link"
        fi
    done

    chmod 700 "/home/mods/$mod"
done

echo "Creating user view access..."
for user in $USERS; do
    mkdir -p "/home/users/$user/all_blogs"
    for author in $AUTHORS; do
        link="/home/users/$user/all_blogs/$author"
        target="/home/authors/$author/public"
        if [ ! -L "$link" ]; then
            ln -s "$target" "$link"
            chmod 755 "$target"
        fi
    done
    chmod 555 "/home/users/$user/all_blogs"
done

echo "Revoking access from removed users..."
for old_user in $PREV_USERS; do
    if ! echo "$USERS" | grep -qw "$old_user"; then
        chmod -R 000 "/home/users/$old_user"
    fi
done

for old_author in $PREV_AUTHORS; do
    if ! echo "$AUTHORS" | grep -qw "$old_author"; then
        setfacl -bR "/home/authors/$old_author"
        chmod -R 000 "/home/authors/$old_author"
    fi
done

for old_mod in $PREV_MODS; do
    if ! echo "$MODS" | grep -qw "$old_mod"; then
        chmod -R 000 "/home/mods/$old_mod"
    fi
done

echo "Granting admin group ACLs..."
for dir in /home/authors/* /home/users/* /home/mods/*; do
    setfacl -R -m g:g_admin:rwx "$dir"
    setfacl -d -m g:g_admin:rwx "$dir"
done

touch "/var/log/blog_activity.log"
chown root:g_admin "/var/log/blog_activity.log"
setfacl -m g:g_author:-w- "/var/log/blog_activity.log"
setfacl -m group::rwx "/var/log/blog_activity.log"

echo "✅ Users and permissions updated."

