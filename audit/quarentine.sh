#!/bin/bash

# Constants for quarantine locations
QUARANTINE_ROOT="/var/quarantine"
TIMESCRIPT_QUARANTINE="$QUARANTINE_ROOT/timescripts"
DATABASE_QUARAN TINE="$QUARANTINE_ROOT/databases"
TERMINAL_QUARANTINE="$QUARANTINE_ROOT/terminals"
MEDIA_QUARANTINE="$QUARANTINE_ROOT/media"

# Create quarantine directories if they don't exist
setup_quarantine_dirs() {
    for dir in "$TIMESCRIPT_QUARANTINE" "$DATABASE_QUARANTINE" "$TERMINAL_QUARANTINE" "$MEDIA_QUARANTINE"; do
        mkdir -p "$dir"
        chmod 700 "$dir"
    done
}

# Function to quarantine timescripts
quarantine_timescript() {
    local script_path="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename=$(basename "$script_path")
    
    # Backup original permissions
    local original_perms=$(stat -c %a "$script_path")
    
    # Move to quarantine with timestamp
    mv "$script_path" "$TIMESCRIPT_QUARANTINE/${filename}_${timestamp}"
    echo "Quarantined timescript: $script_path to $TIMESCRIPT_QUARANTINE/${filename}_${timestamp}"
    
    # Log the quarantine action
    echo "$(date): Quarantined timescript $script_path with permissions $original_perms" >> "$QUARANTINE_ROOT/quarantine.log"
}

# Function to quarantine database files
quarantine_database() {
    local db_path="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename=$(basename "$db_path")
    
    # Create compressed backup
    tar czf "$DATABASE_QUARANTINE/${filename}_${timestamp}.tar.gz" "$db_path"
    echo "Quarantined database: $db_path to $DATABASE_QUARANTINE/${filename}_${timestamp}.tar.gz"
}

# Function to quarantine access terminal configurations
quarantine_terminal() {
    local terminal_config="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename=$(basename "$terminal_config")
    
    # Backup and disable terminal config
    cp "$terminal_config" "$TERMINAL_QUARANTINE/${filename}_${timestamp}"
    chmod 000 "$terminal_config"
    echo "Quarantined terminal config: $terminal_config to $TERMINAL_QUARANTINE/${filename}_${timestamp}"
}

# Function to quarantine media files
quarantine_media() {
    local media_path="$1"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local filename=$(basename "$media_path")
    
    # Move media to quarantine with restricted permissions
    mv "$media_path" "$MEDIA_QUARANTINE/${filename}_${timestamp}"
    chmod 400 "$MEDIA_QUARANTINE/${filename}_${timestamp}"
    echo "Quarantined media file: $media_path to $MEDIA_QUARANTINE/${filename}_${timestamp}"
}

# Main execution
setup_quarantine_dirs

# Example usage for /etc/init.d/ts.sh
if [ -f "/etc/init.d/ts.sh" ]; then
    quarantine_timescript "/etc/init.d/ts.sh"
fi

# List of recommended files to quarantine:
QUARANTINE_RECOMMENDATIONS=(
    # Timescripts
    "/etc/init.d/ts.sh"
    "/etc/cron.d/timescript"
    "/usr/local/bin/ts_*.sh"
    
    # Database files
    "/var/lib/suspicious.db"
    "/opt/database/unverified.db"
    
    # Terminal configs
    "/etc/terminal/suspicious_access.conf"
    "/etc/ssh/suspicious_keys"
    
    # Media files
    "/var/www/uploads/unverified/*"
    "/tmp/suspicious_media/*"
)

# You can loop through recommendations and quarantine them:
# for item in "${QUARANTINE_RECOMMENDATIONS[@]}"; do
#     if [ -f "$item" ]; then
#         case "$item" in
#             *.sh|*/ts_*) quarantine_timescript "$item" ;;
#             *.db) quarantine_database "$item" ;;
#             *.conf|*_keys) quarantine_terminal "$item" ;;
#             */media/*|*/uploads/*) quarantine_media "$item" ;;
#         esac
#     fi
# done
