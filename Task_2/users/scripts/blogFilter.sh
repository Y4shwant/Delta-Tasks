#!/bin/bash
MODNAME=$(whoami)
MOD_HOME="/home/mods/$MODNAME"
BLACKLIST="$MOD_HOME/blacklist.txt"


# Read blacklist words, removing comments and trimming whitespace
mapfile -t BLACKLIST_WORDS < <(grep -vE '^\s*#|^\s*$' "$BLACKLIST" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

for AUTHOR_SYMLINK in "$MOD_HOME/authors_public"/*; do
    [[ -e "$AUTHOR_SYMLINK" ]] || continue

    AUTHOR_BLOG_DIR=$(readlink -f "$AUTHOR_SYMLINK")

    # Assuming author folder is two levels above blog dir
    AUTHOR=$(basename "$(dirname "$AUTHOR_BLOG_DIR")")
    echo "Author identified: $AUTHOR"

    BLOG_DIR="$AUTHOR_BLOG_DIR"
    shopt -s nullglob
    flag=true
    for BLOG_FILE in "$BLOG_DIR"/*; do
        echo "Found blog file: $(basename "$BLOG_FILE")"
        flag=false
        # Resolve blog file symlink to actual target file
        REAL_BLOG_FILE=$(readlink -f "$BLOG_FILE")

        TEMP_FILE=$(mktemp)
        MATCH_COUNT=0
        LINE_NO=0

        while IFS= read -r LINE || [[ -n "$LINE" ]]; do
            ((LINE_NO++))
            LINE_MODIFIED="$LINE"

            for WORD in "${BLACKLIST_WORDS[@]}"; do
                # Escape regex metacharacters for perl
                PATTERN=$(printf '%s' "$WORD" | perl -pe 's/([\\\^\$\.\|\?\*\+\(\)\[\]\{\}])/\\$1/g')
                REGEX="(?i)$PATTERN"

                MATCHES=$(grep -o -i -F "$WORD" <<< "$LINE" | wc -l)
                if (( MATCHES > 0 )); then
                    for ((i=0; i<MATCHES; i++)); do
                        echo "Found blacklisted word '$WORD' in $REAL_BLOG_FILE at line $LINE_NO"
                    done
                    MATCH_COUNT=$((MATCH_COUNT + MATCHES))
                fi

                # Replace with asterisks of equal length
                LEN=${#WORD}
                CENSOR=$(printf '%*s' "$LEN" '' | tr ' ' '*')
                LINE_MODIFIED=$(perl -pe "s/$REGEX/$CENSOR/g" <<< "$LINE_MODIFIED")
            done

            echo "$LINE_MODIFIED" >> "$TEMP_FILE"
        done < "$REAL_BLOG_FILE"

        mv "$TEMP_FILE" "$REAL_BLOG_FILE"
        sudo /usr/local/bin/fix_blog_owner.sh "$REAL_BLOG_FILE" "$AUTHOR" "$MODNAME"
        echo "Total blacklisted words found in $(basename "$REAL_BLOG_FILE"): $MATCH_COUNT"

        if (( MATCH_COUNT > 5 )); then
            echo "Blog $(basename "$REAL_BLOG_FILE") is archived due to excessive blacklisted words."
            rm "$BLOG_FILE"
            sudo update_blog_status.sh "$AUTHOR" "$(basename "$REAL_BLOG_FILE")" "$MATCH_COUNT"
        fi
    done
    if [ "$flag" = true ]; then
        echo "No blogs found in public directory of $AUTHOR"
    fi
    shopt -u nullglob
done

echo "Blog filtering completed."
