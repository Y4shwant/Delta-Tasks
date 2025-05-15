#!/bin/bash

# Path config
USERNAME=$(whoami)
HOME_DIR="/home/authors/$USERNAME"
BLOGS_DIR="$HOME_DIR/blogs"
PUBLIC_DIR="$HOME_DIR/public"
YAML_FILE="$HOME_DIR/blogs.yaml"
FILENAME="$2"

publish_article() {
    if [ ! -f "$BLOGS_DIR/$FILENAME" ]; then
        echo "❌ Error: '$FILENAME' not found in $BLOGS_DIR"
        exit 1
    fi

    echo "Available categories:"
    echo "1) Sports"
    echo "2) Cinema"
    echo "3) Technology"
    echo "4) Travel"
    echo "5) Food"
    echo "6) Lifestyle"
    echo "7) Finance"
    echo ""
    read -p "Enter category order (comma-separated, e.g., 2,1,3): " category_order

    mkdir -p "$PUBLIC_DIR"
    ln -sf "$BLOGS_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
    chmod o+r "$BLOGS_DIR/$FILENAME"

    echo "- file_name: \"$FILENAME\"" >> "$YAML_FILE"
    echo "  publish_status: true" >> "$YAML_FILE"
    echo "  cat_order: [$(echo "$category_order" | sed 's/ //g')]" >> "$YAML_FILE"

    echo "'$FILENAME' published and added to blogs.yaml"
}

archive_article() {
    if [ ! -f "$BLOGS_DIR/$FILENAME" ]; then
        echo "Error: '$FILENAME' not found in $BLOGS_DIR"
        exit 1
    fi

    if [ -L "$PUBLIC_DIR/$FILENAME" ]; then
        rm "$PUBLIC_DIR/$FILENAME"
        echo "Removed symlink from public directory."
    else
        echo "No symlink found in public directory for '$FILENAME'."
    fi

    chmod o-r "$BLOGS_DIR/$FILENAME"
    echo "Revoked read permissions for others."

    TEMP_FILE=$(mktemp)
    in_entry=false
    while IFS= read -r line; do
        if echo "$line" | grep -q "file_name: \"$FILENAME\""; then
            in_entry=true
            echo "$line" >> "$TEMP_FILE"
            continue
        fi

        if $in_entry; then
            if echo "$line" | grep -q "publish_status:"; then
                echo "  publish_status: false" >> "$TEMP_FILE"
                continue
            elif echo "$line" | grep -q "cat_order:"; then
                echo "$line" >> "$TEMP_FILE"
                in_entry=false
                continue
            fi
        fi

        echo "$line" >> "$TEMP_FILE"
    done < "$YAML_FILE"

    mv "$TEMP_FILE" "$YAML_FILE"
    echo "'$FILENAME' archived successfully."
}



delete_article() {
    if [ -L "$PUBLIC_DIR/$FILENAME" ]; then
        rm "$PUBLIC_DIR/$FILENAME"
        echo "Removed symlink from public directory."
    else
        echo "No symlink found in public for $FILENAME."
    fi

    if [ -f "$BLOGS_DIR/$FILENAME" ]; then
        rm "$BLOGS_DIR/$FILENAME"
        echo "Deleted blog file from blogs directory."
    else
        echo "No file named $FILENAME found in blogs."
    fi

    TEMP_FILE=$(mktemp)
    in_entry=false
    while IFS= read -r line; do
        if echo "$line" | grep -q "file_name: \"$FILENAME\""; then
            in_entry=true
            continue
        fi
        if $in_entry; then
            if echo "$line" | grep -q "file_name:"; then
                in_entry=false
                echo "$line" >> "$TEMP_FILE"
            fi
        else
            echo "$line" >> "$TEMP_FILE"
        fi
    done < "$YAML_FILE"

    mv "$TEMP_FILE" "$YAML_FILE"
    echo "Removed blog metadata from YAML."
}

edit_article() {
    if [ ! -f "$BLOGS_DIR/$FILENAME" ]; then
        echo "Blog file $FILENAME does not exist in blogs directory."
        return
    fi

    echo "Choose new category order for $FILENAME (e.g., 2,1,4):"
    echo "1: Sports"
    echo "2: Cinema"
    echo "3: Technology"
    echo "4: Travel"
    echo "5: Food"
    echo "6: Lifestyle"
    echo "7: Finance"
    echo -n "Enter comma-separated category numbers: "
    read new_order

    if [[ ! "$new_order" =~ ^[1-7](,[1-7])*$ ]]; then
        echo "Invalid format. Use comma-separated values between 1-7."
        return
    fi

    TEMP_FILE=$(mktemp)
    in_entry=false
    while IFS= read -r line; do
        if echo "$line" | grep -q "file_name: \"$FILENAME\""; then
            in_entry=true
            echo "$line" >> "$TEMP_FILE"
            continue
        fi

        if $in_entry; then
            if echo "$line" | grep -q "cat_order:"; then
                echo "      cat_order: [${new_order//,/\,}]" >> "$TEMP_FILE"
                continue
            fi
            if echo "$line" | grep -q "file_name:"; then
                in_entry=false
            fi
        fi
        echo "$line" >> "$TEMP_FILE"
    done < "$YAML_FILE"

    mv "$TEMP_FILE" "$YAML_FILE"
    echo "Updated category order for $FILENAME."
}

if [ "$1" == "-p" ]; then
    publish_article
    exit
elif [ "$1" == "-a" ]; then
    archive_article
    exit
elif [ "$1" == "-d" ]; then
    delete_article
    exit
elif [ "$1" == "-e" ]; then
    edit_article
    exit
else
    echo "Usage: $0 {-p|-a|-d|-e} filename"
    exit 1
fi
