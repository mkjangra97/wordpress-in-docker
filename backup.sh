#!/bin/bash
# Combined WP backup: DB dump (gz) + themes & plugins (separate .tar.gz)
# Minimal + cron-friendly. Keep last 3 backups per type.
# Save: /home/manish/wp-backup.sh
# Make executable: sudo chmod +x /home/manish/wp-backup.sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

# ---------- CONFIG ----------
WP_CONTAINER=wordpress_container_name # Change this to your WP container name
DB_CONTAINER=database_container_name # Change this to your DB container name
DB_USER=database_username # Change this to your DB username
DB_PASS=database_password # Change this to your DB password
DATABASE=mysql_database_name # Change this to your MySQL database name

SYS_USER=system_username_for_file_ownership # Change this to your system username
BACKUP_BASE="/home/${SYS_USER}/wp-backups" # Base backup directory
DB_DIR="${BACKUP_BASE}/db" # Directory for DB backups
WP_CONTENT_DIR="${BACKUP_BASE}/wp-content" # Directory for WP content backups

DATE=$(date +"%Y-%m-%d_%H-%M-%S")
TMP_DIR="/tmp/wp-backup-${DATE}"

# how many files to keep
KEEP=3

# ---------- PREPARE ----------
mkdir -p "${DB_DIR}" "${WP_CONTENT_DIR}" "${TMP_DIR}"
chown -R "${SYS_USER}:${SYS_USER}" "${BACKUP_BASE}" 2>/dev/null || true

# ---------- 1) DATABASE DUMP (stream from container -> host file -> gzip) ----------
DB_FILE="${TMP_DIR}/db.sql"
DB_GZ_FILE="${DB_DIR}/db-${DATE}.sql.gz"

# run mysqldump inside DB container and write to tmp file on host
docker exec "${DB_CONTAINER}" sh -c "exec mysqldump -u'${DB_USER}' -p'${DB_PASS}' '${DATABASE}'" > "${DB_FILE}" 2>/dev/null || true

if [ -s "${DB_FILE}" ]; then
  gzip -c "${DB_FILE}" > "${DB_GZ_FILE}" && rm -f "${DB_FILE}"
  chown "${SYS_USER}:${SYS_USER}" "${DB_GZ_FILE}" 2>/dev/null || true
  echo "Created DB backup: ${DB_GZ_FILE}"
else
  echo "DB dump empty or failed; skipping DB backup."
  rm -f "${DB_FILE}"
fi

# ---------- 2) COPY THEMES & PLUGINS INTO TMP ----------
mkdir -p "${TMP_DIR}/themes" "${TMP_DIR}/plugins"

# copy contents (trailing '/.' behaviour) — if fails, continue
docker cp "${WP_CONTAINER}:/var/www/html/wp-content/themes/." "${TMP_DIR}/themes/" 2>/dev/null || true
docker cp "${WP_CONTAINER}:/var/www/html/wp-content/plugins/." "${TMP_DIR}/plugins/" 2>/dev/null || true

# ---------- 3) CREATE TAR.GZ ARCHIVES (contents only) ----------
if [ -n "$(ls -A "${TMP_DIR}/themes" 2>/dev/null)" ]; then
  tar -C "${TMP_DIR}/themes" -czf "${WP_CONTENT_DIR}/wp-themes-${DATE}.tar.gz" .
  chown "${SYS_USER}:${SYS_USER}" "${WP_CONTENT_DIR}/wp-themes-${DATE}.tar.gz" 2>/dev/null || true
  echo "Created themes archive: ${WP_CONTENT_DIR}/wp-themes-${DATE}.tar.gz"
else
  echo "No themes found to archive."
fi

if [ -n "$(ls -A "${TMP_DIR}/plugins" 2>/dev/null)" ]; then
  tar -C "${TMP_DIR}/plugins" -czf "${WP_CONTENT_DIR}/wp-plugins-${DATE}.tar.gz" .
  chown "${SYS_USER}:${SYS_USER}" "${WP_CONTENT_DIR}/wp-plugins-${DATE}.tar.gz" 2>/dev/null || true
  echo "Created plugins archive: ${WP_CONTENT_DIR}/wp-plugins-${DATE}.tar.gz"
else
  echo "No plugins found to archive."
fi

# ---------- 4) CLEANUP TMP ----------
rm -rf "${TMP_DIR}"

# ---------- 5) PURGE: keep only latest $KEEP files (count-based) ----------
cd "${DB_DIR}" 2>/dev/null || true
ls -1t db-*.sql.gz 2>/dev/null | sed -n "$((KEEP+1)),\$p" | xargs -r rm -f

cd "${WP_CONTENT_DIR}" 2>/dev/null || true
ls -1t wp-themes-*.tar.gz 2>/dev/null | sed -n "$((KEEP+1)),\$p" | xargs -r rm -f
ls -1t wp-plugins-*.tar.gz 2>/dev/null | sed -n "$((KEEP+1)),\$p" | xargs -r rm -f

echo "Backup run finished. Backups stored under: ${BACKUP_BASE}"
exit 0


# Ye sab Step karne ke baad sudo nano /etc/crontab me jaake us file ka path de do jaise maine aapko niche diya hai.
# 0 2 * * * /bin/bash /home/username/wp-backups/backup.sh
# backup.sh file ko chmod +x karna na bhoolna. aur chown $USER:$USER bhi kar dena.


