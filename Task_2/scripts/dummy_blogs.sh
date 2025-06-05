#!/bin/bash

set -x

AUTHORS_DIR="/home/authors"
NUM_BLOGS=4
CATEGORIES=(1 2 3 4 5 6 7)



for author_path in "$AUTHORS_DIR"/*; do
    [ -d "$author_path" ] || continue
    [ -r "$author_path" ] && [ -x "$author_path" ] || continue
   

    author=$(basename "$author_path")
    blogs_dir="$author_path/blogs"
    public_dir="$author_path/public"
    yaml_file="$author_path/blogs.yaml"
    if ! [ -w "$yaml_file" ] && ! [ -f "$yaml_file" ]; then
        echo "Skipping $author: blogs.yaml not accessible."
        continue
    fi
    mkdir -p "$blogs_dir" "$public_dir"

    for ((i = 1; i <= NUM_BLOGS; i++)); do
        blog_name="blog_$c"
        ((c++))
        blog_path="$blogs_dir/$blog_name"

        # Create blog file
        touch "$blog_path"
        chown $author:g_author "$blog_path"
        # Create symlink
        ln -sf "$blog_path" "$public_dir/$blog_name"

        # Choose 1–3 random category numbers
        cat_count=$((RANDOM % 3 + 1))
        shuffled=($(shuf -e "${CATEGORIES[@]}"))
        selected=("${shuffled[@]:0:$cat_count}")

        # Create YAML-safe category array (comma-separated)
        cat_list=$(IFS=, ; echo "${selected[*]}")

        # Append to blogs.yaml using yq safely
        yq -i '
          .blogs += [{
            "file_name": "'"$blog_name"'",
            "publish_status": true,
            "cat_order": ['"$cat_list"']
          }]
        ' "$yaml_file"
    done
done
