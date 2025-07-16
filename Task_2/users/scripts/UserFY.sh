#!/bin/bash

users="/configs/sysad-1-users.yaml"
userpref="/configs/sysad-1-userpref.yaml"

mapfile -t actual_users < <(yq '.users[].username' "$users" | sort)
mapfile -t pref_users < <(yq '.users[].username' "$userpref" | sort)
mapfile -t authors < <(yq '.authors[].username' "$users" | sort)

if [[ "${actual_users[*]}" != "${pref_users[*]}" ]]; then
    echo "Mismatch between user list and user preferences. Aborting."
    exit 1
fi

declare -A blog_categories
declare -A blog_assign_count
declare -A blog_authors

# Extract blogs and metadata
for author in "${authors[@]}"; do
    blog_file="/home/authors/$author/blogs.yaml"
    if [[ -f "$blog_file" ]]; then
        while IFS= read -r file; do
            cat_nums=($(yq e ".blogs[] | select(.file_name == \"$file\") | .cat_order[]" "$blog_file"))
            categories=""
            for num in "${cat_nums[@]}"; do
                cat_name=$(yq e ".categories.$num" "$blog_file")
                categories+="$cat_name "
            done
            categories=$(echo "$categories" | xargs)
            if [[ -n "$file" && -n "$categories" ]]; then
                blog_categories["$file"]="$categories"
                blog_assign_count["$file"]=0
                blog_authors["$file"]="$author"
            fi
        done < <(yq '.blogs[] | select(.publish_status == true) | .file_name' "$blog_file")
    fi
done

total_blogs=${#blog_categories[@]}
total_users=${#actual_users[@]}
max_assign=$(( (total_users * 3 + total_blogs - 1) / total_blogs ))


# Precompute sorted blog lists per user
declare -A user_sorted_blogs
for user in "${actual_users[@]}"; do
    declare -A scores=()
    pref1=$(yq ".users[] | select(.username == \"$user\") | .pref1" "$userpref")
    pref2=$(yq ".users[] | select(.username == \"$user\") | .pref2" "$userpref")
    pref3=$(yq ".users[] | select(.username == \"$user\") | .pref3" "$userpref")

    for file in "${!blog_categories[@]}"; do
        IFS=' ' read -r -a cats <<< "${blog_categories[$file]}"
        score=0
        for i in "${!cats[@]}"; do
            [[ "${cats[$i]}" == "$pref1" ]] && (( score += (10 - i*3) ))
            [[ "${cats[$i]}" == "$pref2" ]] && (( score += (7 - i*2) ))
            [[ "${cats[$i]}" == "$pref3" ]] && (( score += 3 ))
        done
        scores["$file"]=$score
    done

    user_sorted_blogs["$user"]=$(for file in "${!scores[@]}"; do
        echo "$file ${scores[$file]}"
    done | sort -k2 -nr | awk '{print $1}')
done


# Assign blogs: 3 rounds
for round in {1..3}; do
    echo "[*] Round $round assigning blogs..."
    for user in "${actual_users[@]}"; do
        out_path="/home/users/$user/fyp.yaml"
        [[ $round -eq 1 ]] && echo "Recommended blogs:" > "$out_path"

        sorted_blogs="${user_sorted_blogs["$user"]}"

        for file in $sorted_blogs; do
            if (( blog_assign_count["$file"] < max_assign )); then
                echo "  - blog: $file by ${blog_authors[$file]}" >> "$out_path"
                (( blog_assign_count["$file"]++ ))

                # Remove assigned blog from user’s sorted list
                user_sorted_blogs["$user"]=$(echo "$sorted_blogs" | grep -v "^$file$")
                break
            fi
        done
    done
done

# Set permissions
for user in "${actual_users[@]}"; do
    chmod 644 "/home/users/$user/fyp.yaml"
done
