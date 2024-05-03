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
for folder in "${folders[@]}"; do
    find "$folder" -type f -print0 | while IFS= read -r -d '' file; do
        if [[ $(get_checksum "$file") != $(get_checksum "$HOME/$file") ]]; then
            modified_files+=("$file")
        fi
    done
done

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
    # quitting
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
                # Get the relative path of the file
                relative_path="${file#"$folder"/}"
                # Construct the destination path
                destination="$HOME/$relative_path"
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
            # Get the relative path of the file
            relative_path="${file#"$folder"/}"
            # Construct the destination path
            destination="$HOME/$relative_path"
            # Copy the file
            cp -rf "$base/$file" "$destination"
        fi
    done
done
