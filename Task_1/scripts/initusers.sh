#!/bin/bash

set -e

YAML_FILE="$(dirname "$0")/../sysad-1-users.yaml"

PREV_USERS=$(getent passwd | awk -F: '/\/home\/users\// {print $1}')
PREV_AUTHORS=$(getent passwd | awk -F: '/\/home\/authors\// {print $1}')
PREV_MODS=$(getent passwd | awk -F: '/\/home\/mods\// {print $1}')

echo "Creating groups..."
for group in g_user g_author g_mod g_admin; do
    if ! getent group "$group" >/dev/null; then
        sudo groupadd "$group"
        echo " Group created: $group"
    fi
done

create_user() {
    local username=$1
    local group=$2
    local homedir=$3
    local user_home="$homedir/$username"

    if id "$username" &>/dev/null; then
        echo "User $username already exists."

        # Check if home directory exists
        if [ ! -d "$user_home" ]; then
            echo "Home directory $user_home missing. Creating it..."
            sudo mkdir -p "$user_home"
            sudo chown -R "$username:$group" "$user_home"
            sudo chmod 710 "$user_home"
            echo "Home directory created for $username at $user_home"
        fi
    else
        echo "Creating user $username in group $group with home $user_home"
        sudo useradd -m -d "$user_home" -g "$group" "$username"
        sudo chown -R "$username:$group" "$user_home"
        sudo chmod 710 "$user_home"
    fi
}

#creating users
ADMINS=$(yq '.admins[].username' "$YAML_FILE")
echo "Creating Admins..."
for username in $ADMINS; do
    create_user "$username" g_admin "/home/admin"
   
done

AUTHORS=$(yq '.authors[].username' "$YAML_FILE")
echo "Creating Authors..."
for username in $AUTHORS; do
    create_user "$username" g_author "/home/authors"
    sudo mkdir -p "/home/authors/$username/blogs"
    sudo mkdir -p "/home/authors/$username/public"
    echo "Set up blogs/ and public/ for $username"
   

    # Initialize blogs.yaml if not exists
    yaml_file="/home/authors/$username/blogs.yaml"
    if [ ! -f "$yaml_file" ]; then
        cat <<EOF | sudo tee "$yaml_file" > /dev/null
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
        sudo chown "$username:g_author" "$yaml_file"
        sudo chmod 644 "$yaml_file"
        echo "Initialized blogs.yaml for $username"
    fi
done

MODS=$(yq '.mods[].username' "$YAML_FILE")
echo "Creating Moderators..."
for username in $MODS; do
    create_user "$username" g_mod "/home/mods"
   
done

USERS=$(yq '.users[].username' "$YAML_FILE")
echo "Creating Users..."
for username in $USERS; do
    create_user "$username" g_user "/home/users"
done
#permissions
for user in $USERS; do
    sudo chmod 710 "/home/users/$user"
done

for author in $AUTHORS; do
    sudo chmod 710 "/home/authors/$author"
    sudo setfacl -b "/home/authors/$author/blogs"
    sudo setfacl -m u::rwx "/home/authors/$author/blogs"

done

# Setting ACLs for mods
for mod in $MODS; do
    authors=$(yq ".mods[] | select(.username == \"$mod\") | .authors[]" "$YAML_FILE")

    sudo touch /home/mods/$mod/blacklist.txt
    sudo chown $mod:g_admin /home/mods/$mod/blacklist.txt
    sudo chmod 770 /home/mods/$mod/blacklist.txt
    echo "# please write one word per line" >> /home/mods/$mod/blacklist.txt

    
    # Remove old ACLs
    for dir in /home/authors/*/public; do
        sudo setfacl -x u:$mod "$dir" 2>/dev/null || true
    done

    for author in $authors; do
        sudo setfacl -m u:$mod:x "/home/authors/$author"

        sudo setfacl -m u:$mod:rwx "/home/authors/$author/public"
        sudo setfacl -m u:$mod:rwx "/home/authors/$author/blogs"
        sudo setfacl -d -m u:$mod:rwx "/home/authors/$author/blogs"
        sudo setfacl -d -m m::rwx "/home/authors/$author/blogs"
        sudo setfacl -d -m u:$mod:rwx "/home/authors/$author/public"
        sudo setfacl -d -m m::rwx "/home/authors/$author/public"

        echo "Granted $mod access to $author's public and blogs folders"

    done

    mkdir -p "/home/mods/$mod/authors_public"
    for author in $authors; do
        link="/home/mods/$mod/authors_public/$author"
        target="/home/authors/$author/public"
        if [ ! -L "$link" ]; then
            ln -s "$target" "$link"
            echo "Created symlink for $mod -> $author"
        else
            echo "Symlink already exists for $mod -> $author"
        fi
    done

    sudo chmod 700 "/home/mods/$mod"
done

# Set up all_blogs for users
for user in $USERS; do
    mkdir -p "/home/users/$user/all_blogs"
    for author in $AUTHORS; do
        link="/home/users/$user/all_blogs/$author"
        target="/home/authors/$author/public"
        if [ ! -L "$link" ]; then
            ln -s "$target" "$link"
            echo "Linked $user to $author's public blog"
        else
            echo "Symlink already exists for $user -> $author"
        fi
        sudo chmod 755 "$target"
    done
    sudo chmod 555 "/home/users/$user/all_blogs"
done

#Revoke access

for old_user in $PREV_USERS; do
    if ! echo "$USERS" | grep -qw "$old_user"; then
        perms=$(stat -c '%A' /home/users/$old_user)
        if [ "$perms" != "d---rwx---" ]; then 
            sudo chmod -R 000 "/home/users/$old_user"
            echo "$old_user access revoked"
        fi
    fi
done

for old_author in $PREV_AUTHORS; do
    if ! echo "$AUTHORS" | grep -qw "$old_author"; then
        perms=$(stat -c '%A' /home/authors/$old_author)
        if [ "$perms" != "d---rwx---" ]; then 
            sudo setfacl -bR /home/authors/$old_author
            sudo chmod -R 000 "/home/authors/$old_author"
            echo "$old_author access revoked"
        fi
    fi
done

for old_mod in $PREV_MODS; do
    if ! echo "$MODS" | grep -qw "$old_mod"; then
        perms=$(stat -c '%A' /home/mods/$old_mod)
        if [ "$perms" != "d---rwx---" ]; then 
            sudo chmod -R 000 "/home/mods/$old_mod"
            echo "$old_mod access revoked"
        fi
    fi
done

echo "Users and permissions updated."
for author in $AUTHORS; do
    sudo setfacl -m m::rwx "/home/authors/$author/public"
    sudo setfacl -m m::rwx "/home/authors/$author/blogs"
done
sudo setfacl -R -m g:g_admin:rwx /home/authors/*
sudo setfacl -d -m g:g_admin:rwx /home/authors/*
sudo setfacl -R -m g:g_admin:rwx /home/users/*
sudo setfacl -d -m g:g_admin:rwx /home/users/*
sudo setfacl -R -m g:g_admin:rwx /home/mods/*
sudo setfacl -d -m g:g_admin:rwx /home/mods/*
sudo setfacl -m g:g_user:x /home/authors/*
touch "/var/log/blog_activity.log"
echo "log file created"
sudo chown root:g_admin "/var/log/blog_activity.log"
sudo setfacl -m g:g_author:-w- "/var/log/blog_activity.log"
sudo setfacl -m group::rwx /var/log/blog_activity.log

echo "Pruning stale users (keeping home dirs)..."
for old_user in $PREV_USERS; do
    if ! echo "$USERS" | grep -qw "$old_user"; then
        echo "Disabling $old_user..."
        sudo userdel "$old_user" 2>/dev/null || true
    fi
done

for old_author in $PREV_AUTHORS; do
    if ! echo "$AUTHORS" | grep -qw "$old_author"; then
        echo "Disabling $old_author..."
        sudo userdel "$old_author" 2>/dev/null || true
    fi
done

for old_mod in $PREV_MODS; do
    if ! echo "$MODS" | grep -qw "$old_mod"; then
        echo "Disabling $old_mod..."
        sudo userdel "$old_mod" 2>/dev/null || true
    fi
done



echo "Fixing ownerships of all home directories..."

# Fix admins
for admin in $ADMINS; do
    sudo chown -R "$admin:g_admin" "/home/admin/$admin"
    echo "Ownership fixed for admin: $admin"
done

# Fix authors
for author in $AUTHORS; do
    sudo chown -R "$author:g_author" "/home/authors/$author"
    echo "Ownership fixed for author: $author"
done

# Fix moderators
for mod in $MODS; do
    sudo chown -R "$mod:g_mod" "/home/mods/$mod"
    echo "Ownership fixed for moderator: $mod"
done

# Fix users
for user in $USERS; do
    sudo chown -R "$user:g_user" "/home/users/$user"
    echo "Ownership fixed for user: $user"
done


sudo chown root:g_admin /home/admin
sudo chmod 770 /home/admin
sudo chown root:g_user /home/users
sudo chmod 755 /home/users
sudo chown root:g_author /home/authors
sudo chmod 755 /home/authors
sudo chown root:g_mod /home/mods
sudo chmod 755 /home/mods


for author in $(ls /home/authors); do
    echo "127.0.0.1 $author.blog.in" | sudo tee -a /etc/hosts
done
