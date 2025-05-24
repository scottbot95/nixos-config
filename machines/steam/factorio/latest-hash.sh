#!/usr/bin/env nix-shell
#! nix-shell -i bash -p curl -p gawk -p gnugrep
# The above line ensures bash, curl, awk, grep, and sed are available in the environment

# URL of the SHA256 sums
URL="https://www.factorio.com/download/sha256sums/"

# Download the SHA256 sums and store the output
HASH_OUTPUT=$(curl -s "$URL")

# Check if the download was successful
if [ $? -ne 0 ]; then
    echo "Failed to download SHA256 sums from $URL"
    exit 1
fi

# Use grep to find the first line that matches the pattern for the headless Linux version
# Then extract the hash using awk
HASH=$(echo "$HASH_OUTPUT" | grep -m 1 "factorio-headless_linux_.*\.tar\.xz")

# Check if a hash was found
if [ -z "$HASH" ]; then
    echo "No hash found for factorio-headless Linux version"
    exit 2
fi

# Print the hash
echo "$HASH"