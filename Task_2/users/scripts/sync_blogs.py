#!/usr/bin/env python3

import os
import mysql.connector
import yaml

DB_HOST = "mysql"
DB_USER = "root"
DB_PASSWORD = "rootpass"
DB_NAME = "blogdb"

def sync_blogs():
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        cursor = conn.cursor()

        authors_dir = "/home/authors"
        authors = os.listdir(authors_dir)

        for author in authors:
            blogs_path = os.path.join(authors_dir, author, "blogs.yaml")
            if os.path.isfile(blogs_path):
                with open(blogs_path, "r") as f:
                    data = yaml.safe_load(f)

                    blogs = data.get("blogs", [])
                    for blog in blogs:
                        blog_name = blog.get("file_name", "")
                        publish_status = 1 if blog.get("publish_status", False) else 0
                        cat_order_list = blog.get("cat_order", [])
                        cat_order = ",".join(str(c) for c in cat_order_list)
                        read_count = blog.get("read_count", 0)

                        cursor.execute(
                            """
                            REPLACE INTO blogs (blog_name, author, publish_status, category_order, read_count)
                            VALUES (%s, %s, %s, %s, %s)
                            """,
                            (blog_name, author, publish_status, cat_order, read_count)
                        )
                        print(f"Synced blog: {blog_name} by {author}")

        conn.commit()
        cursor.close()
        conn.close()
        print("All blogs synced successfully.")

    except mysql.connector.Error as err:
        print(f"Database error: {err}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    sync_blogs()
