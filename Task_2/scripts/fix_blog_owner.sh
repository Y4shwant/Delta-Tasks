#!/bin/bash
# Usage: fix_blog_owner.sh <file_path> <owner> <mod_user>

FILE="$1"
OWNER="$2"
MODUSER="$3"

if [[ -z "$FILE" || -z "$OWNER" || -z "$MODUSER" ]]; then
  echo "Usage: $0 <file_path> <owner> <mod_user>"
  exit 1
fi

GROUP="g_author"

# Change ownership to owner:g_author
chown "$OWNER:$GROUP" "$FILE"

# Set permission 755
chmod 755 "$FILE"

# Set ACL for mod user with rw permissions
setfacl -m u:"$MODUSER":rw "$FILE"

