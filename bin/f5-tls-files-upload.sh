#!/bin/bash

# Function to display help
display_help() {
    echo "Usage: $0 [--cert|-c] <cert_file> [--key|-k] <key_file> [--auth-token|-t] <auth_token> [--host|-h] <hostname or IP>"
    echo
    echo "  --cert, -c       Path to the certificate file to upload"
    echo "  --key, -k        Path to the key file to upload"
    echo "  --auth-token, -t X-F5-Auth-Token authentication header value"
    echo "  --host, -h       Hostname, FQDN, or IP address of the BIG-IP device"
    echo "  --help           Display this help message"
    exit 1
}

# Check if no arguments are passed, display help
if [ "$#" -eq 0 ]; then
    display_help
fi

# Parse the arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --cert|-c) cert_file="$2"; shift ;;
        --key|-k) key_file="$2"; shift ;;
        --auth-token|-t) auth_token="$2"; shift ;;
        --host|-h) host="$2"; shift ;;
        --help) display_help ;;
        *) echo "Unknown parameter: $1"; display_help ;;
    esac
    shift
done

# Check if all required arguments are provided
if [ -z "$cert_file" ] || [ -z "$key_file" ] || [ -z "$auth_token" ] || [ -z "$host" ]; then
    echo "Error: Missing required arguments."
    display_help
fi

# Warning and confirmation prompt
echo "WARNING: Uploading these files will overwrite any existing files with the same name on the BIG-IP device."
read -p "Do you wish to proceed? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
    echo "File transfer canceled."
    exit 0
fi

# Function to upload a file
upload_file() {
    local file_path=$1
    local token=$2
    local host=$3
    local file_name=$(basename "$file_path")
    
    # Get file size
    local file_size=$(stat --printf="%s" "$file_path")
    local content_range_end=$((file_size - 1))
    
    echo "Uploading $file_name (size: $file_size bytes) to https://$host..."
    
    # Upload the file using curl
    response=$(curl -s -k -X POST -H "Content-Type: application/octet-stream" \
        -H "X-F5-Auth-Token: $token" \
        -H "Content-Range: 0-${content_range_end}/${file_size}" \
        --data-binary @"$file_path" \
        https://"$host"/mgmt/shared/file-transfer/uploads/"$file_name")
    
    # Print the response
    echo "$response"
    
    # Extract the location from the response (assuming a valid JSON response format)
    local file_location=$(echo "$response" | grep -oP '"localFilePath":"\K[^"]+')
    
    echo "$file_name uploaded to: $file_location"
}

# Upload the certificate and key
upload_file "$cert_file" "$auth_token" "$host"
upload_file "$key_file" "$auth_token" "$host"

# Display final message
echo "Both certificate and key have been uploaded. You can check them on the BIG-IP device."

