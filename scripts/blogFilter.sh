#!/bin/bash
MODNAME=$(whoami)
MOD_HOME="/home/mods/$MODNAME"
BLACKLIST="$MOD_HOME/blacklist.txt"
mapfile -t BLACKLIST_WORDS < <(grep -vE '^\s*#|^\s*$' "$BLACKLIST")

for AUTHOR_SYMLINK in "$MOD_HOME/authors_public"/*; do
    [[ -e "$AUTHOR_SYMLINK" ]] || continue
    AUTHOR_BLOG_DIR=$(readlink -f "$AUTHOR_SYMLINK")
    AUTHOR=$(basename "$(dirname "$AUTHOR_BLOG_DIR")")
    BLOG_DIR="$AUTHOR_BLOG_DIR"

    for BLOG_FILE in "$BLOG_DIR"/*.txt; do
        [[ -e "$BLOG_FILE" ]] || continue
        TEMP_FILE=$(mktemp)
        MATCH_COUNT=0
        LINE_NO=0

        while IFS= read -r LINE || [[ -n "$LINE" ]]; do
            ((LINE_NO++))
            for WORD in "${BLACKLIST_WORDS[@]}"; do
                while [[ "$LINE" =~ $WORD ]]; do
                    MATCH="${BASH_REMATCH[0]}"
                    CENSOR=$(printf '%*s' "${#MATCH}" '' | tr ' ' '*')
                    LINE="${LINE//$MATCH/$CENSOR}"
                    ((MATCH_COUNT++))
                done
            done
            echo "$LINE" >> "$TEMP_FILE"
        done < "$BLOG_FILE"

        mv "$TEMP_FILE" "$BLOG_FILE"

        if (( MATCH_COUNT > 5 )); then
            rm "$AUTHOR_SYMLINK"
            BLOG_NAME=$(basename "$BLOG_FILE")
            update_blog_status.sh "$AUTHOR" "$BLOG_NAME" "$MATCH_COUNT"
        fi
    done
done
