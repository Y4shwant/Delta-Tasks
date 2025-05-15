#!/bin/bash

# Usage: sudo /usr/local/bin/update_blog_status.sh <author_username> <blog_file_name> <count>

AUTHOR="$1"
BLOG_NAME="$2"
COUNT="$3"

YAML_PATH="/home/authors/$AUTHOR/blogs.yaml"

# Safety checks
if [[ ! -f "$YAML_PATH" ]]; then
    echo "YAML file not found at $YAML_PATH"
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo "yq not installed"
    exit 1
fi

# Update publish_status to false and add mod_comments
/usr/bin/yq -i '
  .blogs |= map(
    if .file_name == "'"$BLOG_NAME"'" 
    then .publish_status = false | .mod_comments = "found '"$COUNT"' blacklisted words" 
    else . 
    end
  )
' "$YAML_PATH"

