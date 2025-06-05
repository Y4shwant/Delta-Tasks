#!/bin/bash

# Usage: sudo /usr/local/bin/update_blog_status.sh <author_username> <blog_file_name> <count>

AUTHOR="$1"
BLOG_NAME="$2"
COUNT="$3"

YAML_PATH="/home/authors/$AUTHOR/blogs.yaml"



# Update publish_status to false and add mod_comments
yq eval ".blogs[] |= (
  select(.file_name == \"$BLOG_NAME\") 
  | .publish_status = false 
  | .mod_comments = \"found $COUNT blacklisted words\"
)" -i "$YAML_PATH"






