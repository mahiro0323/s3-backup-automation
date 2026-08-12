#!/bin/bash

set -euo pipefail

# ------------------------------------------------------------
# S3 Backup Automation
# Synchronizes local directories to Amazon S3.
# ------------------------------------------------------------

# launchd has a limited PATH, so common AWS CLI locations are added.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load environment variables
ENV_FILE="${PROJECT_ROOT}/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "ERROR: .env file not found: $ENV_FILE"
    exit 1
fi

# Required environment variable
if [ -z "${S3_BUCKET:-}" ]; then
    echo "ERROR: S3_BUCKET is not configured."
    exit 1
fi

AWS_REGION="${AWS_REGION:-ap-northeast-1}"
AWS_PROFILE="${AWS_PROFILE:-default}"

# Check AWS CLI
if ! command -v aws >/dev/null 2>&1; then
    echo "ERROR: AWS CLI is not installed or not found in PATH."
    exit 1
fi

# Backup target directories
BACKUP_DIRS=(
    "$HOME/Documents"
    "$HOME/Desktop"
    "$HOME/Pictures"
    "$HOME/Downloads"
)

echo "=========================================="
echo "S3 Backup Started"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Bucket: ${S3_BUCKET}"
echo "Region: ${AWS_REGION}"
echo "=========================================="

for SOURCE_DIR in "${BACKUP_DIRS[@]}"; do

    if [ ! -d "$SOURCE_DIR" ]; then
        echo "SKIP: Directory not found: $SOURCE_DIR"
        continue
    fi

    DIR_NAME="$(basename "$SOURCE_DIR")"

    echo "Backing up: $SOURCE_DIR"

    aws s3 sync \
        "$SOURCE_DIR" \
        "s3://${S3_BUCKET}/${DIR_NAME}/" \
        --region "$AWS_REGION" \
        --profile "$AWS_PROFILE" \
        --only-show-errors

    echo "Completed: $DIR_NAME"

done

echo "=========================================="
echo "S3 Backup Completed"
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="
