# Task 2 – Dockerized Blog Server Setup

This directory contains the Dockerized implementation of the blog server setup described in Task 2.

##  Overview

The goal of Task 2 is to streamline the blog server setup from Task 1 using Docker and Docker Compose. This includes:

- Containerizing user and blog management scripts
- Setting up Nginx to serve blog content
- Creating a MySQL database to store user and blog metadata
- Wiring everything together with Docker Compose

---

##  Folder Structure

task2/
├── scripts/ # Bash scripts from Task 1 (symlinked or copied)
├── Dockerfile # User scripts container
├── docker-compose.yml # Multi-container setup
├── nginx/
│ ├── Dockerfile
│ └── default.conf
├── db/
│ └── init.sql # SQL for schema setup
├── README.md # You are here
├── notes.md # (Optional) Development notes and TODOs


##  What Works

-  Scripts from Task 1 are copied into the user container
-  Dockerfile builds a working image for blog management
-  MySQL schema created using raw SQL
-  Basic Nginx config drafted to serve blog files
-  Docker Compose file sets up networking between services

---

##  Services (Docker Compose)

| Service | Description | Status |
|--------|-------------|--------|
| `users` | Bash script container with blog logic | Working |
| `nginx` | Serves blog files by username |  Drafted |
| `db`    | MySQL to store user & blog metadata |  Initializes |

## TODO

Map custom domains like username.blog.in dynamically

Finish and test fifth script

Update scripts to insert metadata into the database

Secure volume permissions for Nginx to access home directories
