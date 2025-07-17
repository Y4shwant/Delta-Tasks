#!/usr/bin/env python3

import os
import mysql.connector
import yaml

DB_HOST = "mysql"
DB_USER = "root"
DB_PASSWORD = "rootpass"
DB_NAME = "blogdb"

def sync_users():
    try:
        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        cursor = conn.cursor()

        users_dir = "/home/users"
        users = os.listdir(users_dir)

        for user in users:
            fyp_path = os.path.join(users_dir, user, "fyp.yaml")
            if os.path.isfile(fyp_path):
                with open(fyp_path, "r") as f:
                    data = yaml.safe_load(f)

                    # Default empty values
                    fyp1 = ""
                    fyp2 = ""
                    fyp3 = ""

                    # Extract from 'Recommended blogs'
                    recommended = data.get("Recommended blogs", [])
                    for item in recommended:
                        if "fyp1" in item:
                            fyp1 = item["fyp1"]
                        if "fyp2" in item:
                            fyp2 = item["fyp2"]
                        if "fyp3" in item:
                            fyp3 = item["fyp3"]

                    cursor.execute(
                        "REPLACE INTO users (username, fyp1, fyp2, fyp3) VALUES (%s, %s, %s, %s)",
                        (user, fyp1, fyp2, fyp3)
                    )
                    print(f"Synced: {user}")

        conn.commit()
        cursor.close()
        conn.close()
        print("All users synced successfully.")

    except mysql.connector.Error as err:
        print(f"Database error: {err}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    sync_users()
