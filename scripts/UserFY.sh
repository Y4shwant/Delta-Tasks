#!/bin/bash
set -x
users="/usr/local/bin/sysad-1-users.yaml"
userpref="/usr/local/bin/sysad-1-userpref.yaml"

mapfile -t actual_users < <(yq '.users[].username' "$users" | sort)
mapfile -t pref_users < <(yq '.users[].username' "$userpref" | sort)
mapfile -t authors < <(yq '.authors[].username' "$users" | sort)

if [[ "${actual_users[*]}" != "${pref_users[*]}" ]]; then
    echo "Mismatch between user list and user preferences. Aborting."
    exit 1
fi
declare -A cat_map=(
  [1]="Sports"
  [2]="Cinema"
  [3]="Technology"
  [4]="Travel"
  [5]="Food"
  [6]="Lifestyle"
  [7]="Finance"
)


declare -A blog_categories
declare -A blog_scores
declare -A blog_assign_count

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
            fi
        done < <(yq '.blogs[] | select(.publish_status == true) | .file_name' "$blog_file")
    fi
done

total_blogs=${#blog_categories[@]}
total_users=${#actual_users[@]}
max_assign=$(( (total_users + total_blogs - 1) / total_blogs ))  

declare -A user_assignments

for user in "${actual_users[@]}"; do
    echo "$user"
    pref1=$(yq ".users[] | select(.username == \"$user\") | .pref1" $userpref)
    pref2=$(yq ".users[] | select(.username == \"$user\") | .pref2" $userpref)
    pref3=$(yq ".users[] | select(.username == \"$user\") | .pref3" $userpref)

    declare -A scores=()
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
    echo "hi"
    sorted_blogs=$(for file in "${!scores[@]}"; do
        echo "$file ${scores[$file]}"
    done | sort -k2 -nr | awk '{print $1}')
    assigned=1
    echo "hello"
    ls /home/users/$user
    echo "Recommended blogs:" > /home/users/$user/fyp.yaml
    for file in $sorted_blogs; do
        if (( blog_assign_count["$file"] < max_assign )); then
            echo "  - blog$assigned: $file" >> /home/users/$user/fyp.yaml
            (( blog_assign_count["$file"]++ ))
            ((assigned++))
        fi
        if ((assigned>=4)); then
            break
        fi
    done
done






