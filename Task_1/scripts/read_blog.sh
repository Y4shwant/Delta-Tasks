#!/bin/bash
set -e

if [ $# -ne 2 ]; then
    echo "Usage: sudo read_blog.sh <author_name> <blog_name>"
    exit 1
fi

AUTHOR="$1"
BLOG="$2"

BLOG_PATH="/home/authors/$AUTHOR/blogs/$BLOG"
LINK="/home/authors/$AUTHOR/public/$BLOG"
YAML_PATH="/home/authors/$AUTHOR/blogs.yaml"

if [ ! -f "$BLOG_PATH" ]; then
    echo "Error: Blog file $BLOG_PATH does not exist."
    exit 1
fi

if [ ! -L "$LINK" ]; then
    echo "Error: Blog file not published."
    exit 1
fi

if [ ! -f "$YAML_PATH" ]; then
    echo "Error: YAML file $YAML_PATH not found."
    exit 1
fi

sudo cat "$BLOG_PATH"

sudo yq eval ".blogs[] |= (
  select(.file_name == \"$BLOG\") 
  | .read_count = ((.read_count // 0) + 1)
)" -i "$YAML_PATH"

