#!/bin/bash
for author in "/home/authors/"*; do
    rm -f $author/blogs/* 2>/dev/null
    rm -f $author/public/* 2>/dev/null
    sudo yq eval '.blogs = []' "$author/blogs.yaml" -i 2>/dev/null
done
echo "done"