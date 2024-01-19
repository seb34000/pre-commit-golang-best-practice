#!/usr/bin/env bash
#
# Script to suggest renaming of functions and methods in Go files
# according to specified naming guidelines to avoid repetition.
#
set -e -o pipefail

# Check for prerequisites
if ! command -v go &> /dev/null ; then
    echo "Go is not installed or available in the PATH" >&2
    exit 1
fi

if ! command -v awk &> /dev/null ; then
    echo "awk is not installed or available in the PATH" >&2
    exit 1
fi

# Function to suggest new function/method names
suggest_name() {
    local current_name=$1
    local package_name=$2
    local receiver_name=$3

    # DEBUG
    echo "Current name: $current_name"
    echo "Package name: $package_name"
    echo "Receiver name: $receiver_name"

    # Remove package name from function names
    if [[ "$current_name" == "$package_name"* ]]; then
        echo "${current_name/$package_name/}"
        return
    fi

    # Remove receiver name from method names
    if [[ -n "$receiver_name" && "$current_name" == "$receiver_name"* ]]; then
        echo "${current_name/$receiver_name/}"
        return
    fi

    echo "$current_name"
}

# Process each Go file
for file in "$@"; do
    echo "Processing $file..."
    package_name=$(awk '/package/ {print $2; exit}' "$file")
    echo "Package: $package_name"

    # Extract function and method declarations
    declarations=$(awk '/func/ {print $0}' "$file")

    while IFS= read -r line; do
        # Extract current function/method name
        if [[ "$line" =~ func\ \(*([^\)]*)\)*\ ([^\(]*) ]]; then
            receiver=${BASH_REMATCH[1]}
            current_name=${BASH_REMATCH[2]}
            receiver_name=$(echo "$receiver" | awk '{print $2}' | sed 's/*//g')

            # Suggest new name
            new_name=$(suggest_name "$current_name" "$package_name" "$receiver_name")

            if [[ "$current_name" != "$new_name" ]]; then
                echo "Suggestion: Rename $current_name to $new_name"
            fi
        fi
    done <<< "$declarations"
done

echo "Analysis complete."
