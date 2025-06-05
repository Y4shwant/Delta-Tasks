# Task 1 – Blog Server Setup using Bash Scripts

This task sets up a multi-user blog system on Linux using Bash scripts. Users are assigned roles like authors, moderators, admins, and normal users, with specific directory structures, permissions, and capabilities.

---

## Scripts Included

### 1. `initUsers.sh`
- Reads a `users.yaml` file.
- Creates system users in groups: `g_user`, `g_author`, `g_mod`, `g_admin`.
- Sets up proper directory structures:
  - `/home/users/<username>`
  - `/home/authors/<username>/blogs` and `/public`
  - `/home/mods/<username>`
  - `/home/admin/<username>`
- Assigns permissions:
  - Users have symlinks to all blogs in `/all_blogs`.
  - Moderators get controlled access to specific authors.
  - Admins get full access.
- Supports dynamic updates to reflect changes in YAML.

---

### 2. `manageBlogs.sh`
- Used by authors to manage blogs inside their `blogs/` directory.
- Supports:
  - `-p <file>`: Publish blog to public folder, set categories, update `blogs.yaml`.
  - `-a <file>`: Archive a blog.
  - `-d <file>`: Delete a blog completely.
  - `-e <file>`: Edit blog's categories interactively.

---

### 3. `blogFilter.sh`
- Used by moderators to scan public blogs for blacklisted words.
- Replaces blacklisted words with asterisks (same length).
- Case-insensitive and handles word boundaries.
- If more than 5 violations in a blog:
  - Removes it from moderator view.
  - Archives the blog.
  - Updates `blogs.yaml` with `mod_comments` and `publish_status: false`.

---

### 4. `userFY.sh`
- Can only be run by admin.
- Assigns 3 personalized blogs to each user based on their preferences from `userpref.yaml`.
- Stores result in each user’s `FYI.yaml`.
- Distributes blogs as evenly as possible across users.

---

### 5. `adminPanel.sh`
- Generates admin reports about:
  - Total published/deleted blogs per category.
  - Top 3 most read articles (tracked manually).
- Creates a summary log file.
- Includes a cron job that runs this script:
  - At **3:14 PM** every **Thursday** and **first/last Saturdays** of **Feb, May, Aug, Nov**.

---

## How to Use

```bash
# Run scripts as root/admin where needed
sudo bash initUsers.sh
sudo -u author1 bash manageBlogs.sh -p myblog.txt
sudo -u mod1 bash blogFilter.sh
sudo bash userFY.sh
sudo bash adminPanel.sh
