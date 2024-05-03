#!/bin/bash
# Dieses Skript aktualisiert die Dotfiles, indem es die neueste Version aus dem Git-Repository abruft und dann Dateien ersetzt,
# die nicht vom Benutzer modifiziert wurden, um Änderungen zu bewahren. Die restlichen Dateien werden durch die neuen ersetzt.

cd "$(dirname "$0")"
export base="$(pwd)"

# Load the necessary checksum functions
source ./scriptdata/functions

# Define the folders to update
folders=(".config" ".local")

# Then check which files have been modified since the last update
modified_files=()

# Find all files in the specified folders and their subfolders
while IFS= read -r -d '' file; do
    # Calculate checksums
    base_checksum=$(get_checksum "$base/$file")
    home_checksum=$(get_checksum "$HOME/$file")
    # Compare checksums and add to modified_files if necessary
    if [[ $base_checksum != $home_checksum ]]; then
        modified_files+=("$file")
    fi
done < <(find "${folders[@]}" -type f -print0)


echo "Modified files: ${modified_files[@]}"

# Output all modified files
if [[ ${#modified_files[@]} -gt 0 ]]; then
    echo "The following files have been modified since the last update:"
    for file in "${modified_files[@]}"; do
        echo "$file"
    done
else
    echo "No files have been modified since the last update."
fi


# Then update the repository
git pull
if [[ $? -eq 0 ]]; then
    # Already up to date
    echo "Quitting..."
    exit 0
else
    echo "Update successful."
fi

# Now only replace the files that are not modified by the user
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            if [[ ! " ${modified_files[@]} " =~ " ${file} " ]]; then
                # Construct the destination path
                destination="$HOME/$file"
                # Copy the file
                cp -rf "$base/$file" "$destination"
            fi
        fi
    done
done

# Add the new files, because maybe the update added new files
for folder in "${folders[@]}"; do
    # Find all files (including those in subdirectories) and copy them
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ ! -f "$HOME/$file" ]]; then
            echo "Adding new file: $file"
            # Construct the destination path
            destination="$HOME/$file"
            # Copy the file
            cp -rf "$base/$file" "$destination"
        fi
    done
done
