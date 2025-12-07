# WordPress in Docker with Redis and Backup

This project provides a complete setup for running WordPress with Docker, including a MySQL database and Redis for caching. It also includes a comprehensive backup script to secure your data.

## Features

- **WordPress**: Running on PHP 8.2 and Apache.
- **MySQL 8.4**: Robust database service.
- **Redis**: For object caching to improve performance.
- **Automated Backups**: Script to backup database, themes, and plugins.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/)

## Installation & Setup

1.  **Clone the repository** (if applicable) or navigate to your project directory.

2.  **Configure Environment Variables**
    Create a `.env` file in the root directory to store your secrets. This file is used by `docker-compose.yml`.
    
    ```env
    MYSQL_DATABASE=wordpress
    MYSQL_USER=wordpress_user
    MYSQL_PASSWORD=secure_password
    MYSQL_ROOT_PASSWORD=root_secure_password
    ```

3.  **Start the Services**
    Run the following command to build and start the containers in detached mode:
    
    ```bash
    docker compose up -d
    ```

4.  **Access the Application**
    Open your web browser and go to:
    
    [http://localhost:4600](http://localhost:4600)

## Backup System

The included `backup.sh` script handles backups for the MySQL database and WordPress content (themes and plugins).

### Configuration

Before running the script, open `backup.sh` and update the configuration section to match your environment, specifically the container names and database credentials.

**Important:** Ensure the `DB_CONTAINER` variable in `backup.sh` matches the container name in `docker-compose.yml` (currently `wordpress-database`).

```bash
# Example configuration in backup.sh
WP_CONTAINER="wordpress"
DB_CONTAINER="wordpress-database" # Update this to match docker-compose
DB_USER="wordpress_user"          # Match your .env
DB_PASS='secure_password'         # Match your .env
DATABASE="wordpress"              # Match your .env
```

### Running Backups

1.  **Make the script executable:**
    ```bash
    chmod +x backup.sh
    ```

2.  **Run the script manually:**
    ```bash
    ./backup.sh
    ```

3.  **Automate with Cron:**
    To run the backup daily at 2:00 AM, add the following line to your crontab (`crontab -e`):

    ```cron
    0 2 * * * /bin/bash /path/to/your/project/backup.sh
    ```

    *Note: Ensure the paths in the script (like `BACKUP_BASE`) are valid and writable.*

## Project Structure

- `docker-compose.yml`: Defines the services (WordPress, MySQL, Redis).
- `backup.sh`: Shell script for backing up data.
- `README.md`: Documentation.

## Services Configuration

- **WordPress**: Port `4600`
- **MySQL**: Internal Port `3306`
- **Redis**: Internal Port `6379`
