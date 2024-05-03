#!/bin/bash
# This script updates the dotfiles by pulling the latest version from the git repository and then replace files
# that are not modified by the user to preserve changes. 
# The rest of the files are replaced by the new ones.


cd "$(dirname "$0")"
export base="$(pwd)"


# Load the necessary checksum functions
source ./scriptdata/functions

# Define the folders to update
folders=(".config" ".local")

# Then check which files have been modified since the last update
modified_files=()
for folder in "${folders[@]}"; do
    for file in "$folder"/*; do
        if [[ $(get_checksum "$file") != $(get_checksum "$HOME/$file") ]]; then
            modified_files+=("$file")
        fi
    done
done

# Then update the repository
git pull

# Now only replace the files that are not modified by the user
for folder in "${folders[@]}"; do
    for file in "$folder"/*; do
        if [[ ! " ${modified_files[@]} " =~ " ${file} " ]]; then
            cp -f "$base/$file" "$HOME/$file"
        fi
    done
done

# Add the new files
for folder in "${folders[@]}"; do
    for file in "$folder"/*; do
        if [[ ! -f "$HOME/$file" ]]; then
            cp -f "$base/$file" "$HOME/$file"
        fi
    done
done
