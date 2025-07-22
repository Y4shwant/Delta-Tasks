#!/bin/bash
report_dir="/home/yashwantb/reports"
mkdir -p "$report_dir"
report_file="$report_dir/report-$(date +%Y-%m-%d).txt"

declare -A mod_date
declare -A type_count
declare -A file_size
declare -A count

paths=($(find /home/yashwantb/onsites/httpd ))
echo "Generating report ...." 
echo "files by modification date:" | tee $report_file
for i in ${paths[@]}; do
    if [[ -f "$i" ]]; then
        fname=$(basename "$i")
        echo "$fname" | uniq >> files.txt
        file_size["$i"]=$(stat -c %s "$i")
        echo "$fname ${file_size["$i"]}" >> temp1.txt
        mod_date["$i"]=$(stat -c %y "$i") 
        echo "$fname ${mod_date["$i"]}" >> temp2.txt
    fi
done

#print in chronological order
cat temp2.txt | sort -k2 | uniq | tee -a $report_file
#Print top 5 biggest files in the repo
echo "top 5 largest files in directory" | tee -a $report_file
cat temp1.txt | sort -k2 -nr | uniq | head -5 | tee -a $report_file
#File type count
echo "filetype count:" | tee -a $report_file
awk -F. '{ ext=$NF; if (ext==$0) ext="No_EXT"; type_count[ext]++ } END { for (i in type_count) print i, type_count[i]}' files.txt | sort -nr -k2 | head -5 | tee -a $report_file
#Most active months
echo "Most active months:" | tee -a $report_file
awk '{ split($2, d, "-"); month=d[1]"-"d[2]; count[month]++ } END { for (m in count) print m, count[m] }' temp2.txt | sort -nr -k2 | head -5 | tee -a $report_file
#perms summary
open_count=0
restricted_count=0

for file in "${paths[@]}"; do
    if [[ -f "$file" ]]; then

        perms=$(stat -c %a "$file")
        echo "$file - $perms" | tee -a $report_file
        if [[ "$perms" == "777" ]]; then
            ((open_count++))
            echo "Open file: $file" | tee -a $report_file
        elif [[ $perms =~ ^7[0-5][0-5]$ ]]; then
            ((restricted_count++))
            echo "Restricted file: $file" | tee -a $report_file
        fi
    fi
done

echo "Open files (777): $open_count" | tee -a $report_file
echo "Restricted files (700): $restricted_count" | tee -a $report_file
rm -f files.txt temp1.txt temp2.txt
find "$report_dir" -mtime +7 -print0 | xargs -0 rm -f
# write cronjob using crontab -e 0 0 * * * script.sh


