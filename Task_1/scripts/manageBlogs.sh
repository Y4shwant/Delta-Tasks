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
        echo "Error: '$FILENAME' not found in $BLOGS_DIR"
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

    if [[ ! "$category_order" =~ ^[1-7](,[1-7])*$ ]]; then
        echo "Invalid format. Use comma-separated values between 1-7."
        exit 1
    fi

    mkdir -p "$PUBLIC_DIR"
    ln -sf "$BLOGS_DIR/$FILENAME" "$PUBLIC_DIR/$FILENAME"
    chmod o+r "$BLOGS_DIR/$FILENAME"
    
    yq -i '.blogs += [{
      "file_name": "'"$FILENAME"'",
      "publish_status": true,
      "cat_order": ['"$category_order"']
    }]' "$YAML_FILE"
    echo "'$FILENAME' published and reflected in blogs.yaml"
    echo "$USERNAME published $FILENAME on $(date '+%F %T')" >> "/var/log/blog_activity.log"

}

archive_article() {
    if [ ! -f "$BLOGS_DIR/$FILENAME" ]; then
        echo "❌ Error: '$FILENAME' not found in $BLOGS_DIR"
        exit 1
    fi

    # Remove symlink if it exists
    if [ -L "$PUBLIC_DIR/$FILENAME" ]; then
        rm "$PUBLIC_DIR/$FILENAME"
        echo "Removed symlink from public directory."
    else
        echo "No symlink found in public directory for '$FILENAME'."
    fi

    # Revoke read permission for others on original blog file
    chmod o-r "$BLOGS_DIR/$FILENAME"
    echo "Revoked read permissions for others."

    # Use yq to update publish_status to false for this blog entry
    yq eval ".blogs[] |= (
      select(.file_name == \"$FILENAME\") 
      | .publish_status = false
    )" -i "$YAML_FILE"
  

    echo "'$FILENAME' archived successfully."
    echo "$USERNAME archived $FILENAME on $(date '+%F %T')" >> "/var/log/blog_activity.log"
}





delete_article() {
    # Remove symlink if it exists
    if [ -L "$PUBLIC_DIR/$FILENAME" ]; then
        rm "$PUBLIC_DIR/$FILENAME"
        echo "Removed symlink from public directory."
    else
        echo "No symlink found in public for $FILENAME."
    fi

    # Delete blog file if it exists
    if [ -f "$BLOGS_DIR/$FILENAME" ]; then
        rm "$BLOGS_DIR/$FILENAME"
        echo "Deleted blog file from blogs directory."
    else
        echo "No file named $FILENAME found in blogs."
    fi

    # Remove blog metadata from YAML
    yq eval -i '
      .blogs |= map(select(.file_name != "'"$FILENAME"'"))
    ' "$YAML_FILE"

    echo "Removed blog metadata from YAML."
    echo "$USERNAME deleted $FILENAME on $(date '+%F %T')" >> "/var/log/blog_activity.log"
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
    
    read -p "Enter comma-separated category numbers: " new_order

    if [[ ! "$new_order" =~ ^[1-7](,[1-7])*$ ]]; then
        echo "Invalid format. Use comma-separated values between 1-7."
        return
    fi


    # Convert to proper YAML array syntax
    formatted_array=$(echo "$new_order" | awk -F',' '{ for(i=1;i<=NF;i++) printf "%s%s", $i, (i<NF ? ", " : "") }')

    # Run yq with correct array formatting
    yq eval ".blogs[] |= (
      select(.file_name == \"$FILENAME\") 
      | .cat_order = [${formatted_array}]
    )" -i "$YAML_FILE"


  
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
