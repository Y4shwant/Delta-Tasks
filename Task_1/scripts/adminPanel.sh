#!/bin/bash
set -x

# Only allow execution by users in g_admin group
if ! id -nG "$USER" | grep -qw "g_admin"; then
    echo "Error: Only admin users can run this script."
    exit 1
fi

LOG_FILE="/var/log/blog_activity.log"
CATEGORIES=("Sports" "Cinema" "Technology" "Travel" "Food" "Lifestyle" "Finance")
declare -A published_count deleted_count
declare -A blog_reads
published_logs=()
deleted_logs=()
archived_logs=()
archived_count=0

echo "Generating blog activity report..."

# --- Parse the log file ---
while IFS= read -r line; do
    author=$(awk '{print $1}' <<< "$line")
    action=$(awk '{print $2}' <<< "$line")
    blog=$(awk '{print $3}' <<< "$line")
    timestamp=$(awk '{for(i=5;i<=NF;++i) printf $i" "; print ""}' <<< "$line" | xargs)

    blog_yaml="/home/authors/$author/blogs.yaml"

    if [[ "$action" == "published" && -f "$blog_yaml" ]]; then
        mapfile -t cat_nums < <(yq e ".blogs[] | select(.file_name == \"$blog\") | .cat_order[]" "$blog_yaml")
        for num in "${cat_nums[@]}"; do
            category="${CATEGORIES[$((num-1))]}"
            ((published_count[$category]++))
        done
        published_logs+=("[$timestamp] $author published $blog")
    elif [[ "$action" == "deleted" ]]; then
        ((deleted_count["total"]++))
        deleted_logs+=("[$timestamp] $author deleted $blog")
    elif [[ "$action" == "archived" ]]; then
        ((archived_count++))
        archived_logs+=("[$timestamp] $author archived $blog")
    fi
done < "$LOG_FILE"

# --- Collect read counts from blogs.yaml ---
for author_dir in /home/authors/*; do
    # Skip if inaccessible (e.g., removed authors)
    if [[ ! -r "$author_dir/blogs.yaml" ]]; then
        continue
    fi
    author=$(basename "$author_dir")
    blogs_yaml="$author_dir/blogs.yaml"
    if [[ -f "$blogs_yaml" ]]; then
        mapfile -t entries < <(yq e '.blogs[] | [.file_name, .read_count] | @tsv' "$blogs_yaml")
        for entry in "${entries[@]}"; do
            file=$(cut -f1 <<< "$entry")
            reads=$(cut -f2 <<< "$entry")
            [[ "$reads" == "null" ]] && continue
            blog_reads["$file by $author"]=$reads
        done
    fi
done

# --- Build Report Content ---
report_content="=== Blog Activity Report: $(date '+%F %T') ===\n"

# Published
report_content+="\n-- Published Articles by Category (Sorted) --\n"
for cat in $(for k in "${!published_count[@]}"; do echo "$k ${published_count[$k]}"; done | sort -k2 -nr | cut -d' ' -f1); do
    report_content+="$cat: ${published_count[$cat]}\n"
done

report_content+="\n-- Log Entries for Published Articles --\n"
for log_entry in "${published_logs[@]}"; do
    report_content+="$log_entry\n"
done

# Deleted
report_content+="\n-- Total Deleted Articles: ${deleted_count["total"]:-0} --\n"
report_content+="-- Log Entries for Deleted Articles --\n"
for log_entry in "${deleted_logs[@]}"; do
    report_content+="$log_entry\n"
done

# Archived
report_content+="\n-- Total Archived Articles: ${archived_count:-0} --\n"
report_content+="-- Log Entries for Archived Articles --\n"
for log_entry in "${archived_logs[@]}"; do
    report_content+="$log_entry\n"
done

report_content+="\n-- Top 3 Most Read Articles --\n"

# Create a temporary sorted list of 'read_count<TAB>blog_key'
top_entries=$(for k in "${!blog_reads[@]}"; do
    echo -e "${blog_reads[$k]}\t$k"
done | sort -nr | head -n 3)

if [[ -n "$top_entries" ]]; then
    while IFS=$'\t' read -r reads key; do
        report_content+="$key with $reads reads\n"
    done <<< "$top_entries"
else
    report_content+="No read count data available.\n"
fi


# --- Write to /home/admin/reports/ ---
mkdir -p /home/admin/reports
report_file="/home/admin/reports/blog_report_$(date '+%F_%H-%M-%S').txt"
echo -e "$report_content" > "$report_file"
chmod 640 "$report_file"
chown "$USER":g_admin "$report_file"

# --- Clear log ---
: > "$LOG_FILE"
echo "Report generated at $report_file"
