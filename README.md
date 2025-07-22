# Blog Server - Task 1 & Task 2

This repository contains both tasks for the blog server assignment:

- **Task 1**: User and blog management using Bash scripts
- **Task 2**: Dockerized setup with Nginx, MySQL, and containerized user management

## Structure

- `task1/`: Scripts and notes for the initial manual setup
- `task2/`: Dockerfiles, configs, and integration via Docker Compose

Each folder contains its own README and notes.


# Basic search for "error" in file
grep "error" file.txt  

# Case-insensitive search
grep -i "error" file.txt  

# Show line numbers of matches
grep -n "error" file.txt  

# Recursive search in all files under directory
grep -r "TODO" ./  

# Show lines NOT containing "success"
grep -v "success" file.txt  

# Count occurrences
grep -c "failed" file.txt  

# Show 3 lines before and after match (context)
grep -C 3 "warning" file.txt  

# Show 2 lines after match
grep -A 2 "error" file.txt  

# Show 2 lines before match
grep -B 2 "error" file.txt  

# Match only whole words
grep -w "user" file.txt  

# Print only the matching part (not full line)
grep -o "[0-9]\{3\}-[0-9]\{3\}-[0-9]\{4\}" file.txt  # Extract phone numbers


# Print entire file
awk '{print}' file.txt  

# Print only first column
awk '{print $1}' file.txt  

# Print first and third columns
awk '{print $1, $3}' file.txt  

# Print lines where 3rd column > 100
awk '$3 > 100 {print}' file.txt  

# Sum 2nd column
awk '{sum += $2} END {print sum}' file.txt  

# Average of 2nd column
awk '{sum += $2; count++} END {print sum/count}' file.txt  

# Print line numbers and lines
awk '{print NR, $0}' file.txt  

# Change field separator to comma (CSV)
awk -F, '{print $1, $3}' data.csv  

# Set output field separator
awk 'BEGIN {OFS=" - "} {print $1, $2}' file.txt  

# Print username and shell from /etc/passwd
awk -F: '{print $1, $7}' /etc/passwd

# Find top 5 IPs in access log
awk '{print $1}' access.log | sort | uniq -c | sort -nr | head -5  

# Replace tabs with commas
sed 's/\t/,/g' file.txt  

# Extract only dollar amounts
grep -o '\$[0-9.]*' prices.txt  

# Remove comments and blank lines
sed -e '/^#/d' -e '/^$/d' config.cfg

#!/bin/bash
awk '$7 == "Unbilled" {usage[$3] += $5 + $6} 
     END {for (u in usage) printf "%s %.2f\n", u, usage[u]*0.05}' network_usage.log | sort -k2 -nr > network_bills.txt
awk '$7 == "Unbilled" {usage[$3] += $5 + $6} 
     END {for (u in usage) printf "%s %.2f\n", u, usage[u]*0.05}' network_usage.log | sort -k2 -nr | head -3 > highbills.txt
awk '$7 == "Unbilled" {sum += $5 + $6}
     END {printf "Total due amount: %.2f\n", sum*0.05}' network_usage.log >> highbills.txt
awk '
$7 == "Unbilled" {
    usage[$2] += $5 + $6
    total += $5 + $6
}
END {
    for (u in usage) printf "%s %.2f\n", u, usage[u]*0.05 | "sort -k2 -nr > network_bills.txt"
    for (u in usage) printf "%s %.2f\n", u, usage[u]*0.05 | "sort -k2 -nr | head -3 > highbills.txt"
    printf "Total due amount: %.2f\n", total*0.05 >> "highbills.txt"
}' network_usage.log


touch network_bills.txt
touch highbill.txt
declare -A array1
totcost=0
while IFS=' ' read -r time timee user ip dd ud status; do
    if [[ $status == "Unbilled" ]]; then
        n=$(bc <<< "($dd+$ud) * 0.05")
        totcost=$(bc <<< "$totcost + $n")
        if [[ -n ${array1[$user]} ]]; then
            array1["$user"]=$(bc <<< "${array1[$user]} + $n")
        else
            array1["$user"]=$n
        fi
    fi
    for user in "${!array1[@]}"; do
        echo "$user ${array1[$user]}"
    done | sort -k2nr > network_bills.txt
done < ./network_usage.log
echo "Sorted file:"
cat network_bills.txt
echo "TOP 3 users:"
head -n 3 network_bills.txt | tee highbill.txt
echo "TOTAL COST OVERALL:"
echo "$totcost"

# /etc/nginx/nginx.conf or /etc/nginx/conf.d/loadbalancer.conf

http {
    upstream backend_servers {
        # List of backend servers for load balancing
        server 127.0.0.1:5001;
        server 127.0.0.1:5002;

        # Optional: enable health checks
        # health_check;
    }

    server {
        listen 80;

        # Default root directory for static files
        root /var/www/html;

        # Serve static files for /
        location / {
            index index.html;
            try_files $uri $uri/ =404;
        }

        # Proxy API requests to backend servers
        location /api {
            proxy_pass http://backend_servers;

            # Preserve original host and client IP
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Optional: increase timeout for API calls
            proxy_connect_timeout 10s;
            proxy_read_timeout 30s;
        }
    }
}
http {
    upstream backend_servers {
        server 127.0.0.1:5001;
        server 127.0.0.1:5002;
    }

    server {
        listen 443 ssl;

        server_name example.com;

        # SSL Certificate and Key (generated via Let's Encrypt or self-signed)
        ssl_certificate     /etc/nginx/ssl/example.com.crt;
        ssl_certificate_key /etc/nginx/ssl/example.com.key;

        # Recommended SSL settings
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;

        # Forward API requests to backend
        location /api {
            proxy_pass http://backend_servers;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Serve static files
        location / {
            root /var/www/html;
            index index.html;
        }
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name example.com;

        return 301 https://$host$request_uri;
    }
}

sudo apt update
sudo apt install apache2
sudo systemctl enable --now apache2
# Enable proxying
sudo a2enmod proxy
sudo a2enmod proxy_http

# Enable load balancing
sudo a2enmod proxy_balancer
sudo a2enmod lbmethod_byrequests

# Enable SSL
sudo a2enmod ssl

# Reload Apache after enabling modules
sudo systemctl reload apache2
sudo nano /etc/apache2/sites-available/reverse-proxy.conf
<VirtualHost *:80>
    ServerName example.com

    ProxyPreserveHost On
    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
sudo a2ensite reverse-proxy.conf
sudo systemctl reload apache2
<Proxy "balancer://mycluster">
    BalancerMember http://127.0.0.1:5000
    BalancerMember http://127.0.0.1:5001
</Proxy>

<VirtualHost *:80>
    ServerName example.com

    ProxyPreserveHost On
    ProxyPass / balancer://mycluster/
    ProxyPassReverse / balancer://mycluster/
</VirtualHost>
<VirtualHost *:443>
    ServerName example.com

    SSLEngine on
    SSLCertificateFile /etc/ssl/certs/example.crt
    SSLCertificateKeyFile /etc/ssl/private/example.key

    ProxyPreserveHost On
    ProxyPass / http://localhost:5000/
    ProxyPassReverse / http://localhost:5000/
</VirtualHost>
sudo a2ensite default-ssl.conf
sudo systemctl reload apache2
version: "3.9"  # Compose file format version

services:        # Define all the containers (services)
  web:           # Service name ("web" container)
    image: nginx:latest       # Use official nginx image
    ports:
      - "8080:80"             # Map host:container ports
    volumes:
      - ./html:/usr/share/nginx/html  # Mount host folder into container
    networks:
      - frontend              # Attach to "frontend" network
    depends_on:
      - app                   # Start only after "app" service
    environment:
      - NGINX_HOST=localhost  # Set environment variable inside container

  app:           # Another service ("app" container)
    build: ./app              # Build image from Dockerfile in ./app
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=development
    networks:
      - frontend

networks:       # Define custom networks
  frontend:

volumes:        # Define persistent volumes
  db-data:



