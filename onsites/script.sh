#!bin/bash
declare -A mod_date
declare -A type_count
declare -A file_size

paths=($(find /home/yashwantb/onsites/httpd ))

echo "Generating report ...."
echo "files by modification date:"
for i in ${paths[@]}; do
    if [[ -f "$i" ]]; then
        file_size["$i"]=$(stat -c %s "$i")
        echo "$i ${file_size["$i"]}" >> temp1.txt
        mod_date["$i"]=$(stat -c %y "$i") 
        echo "$i ${mod_date["$i"]}" >> temp2.txt

    fi
done


cat temp2.txt | awk '{print $1,$2}' | sort -k2 | uniq
#Print top 5 biggest files in the repo
echo "top 5 largest files in direcctory"
cat temp1.txt | sort -k2 -nr | uniq | head -5 | awk -F/ '{print $NF}'
rm temp1.txt

#for i in ${mod_date[@]}; do
#    echo "$i"
#done



