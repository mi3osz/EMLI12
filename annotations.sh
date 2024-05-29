#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <root_directory> <repo_directory>"
    exit 1
fi

ROOT_DIR="$1"
REPO_DIR="$2"
MODEL_VERSION="7b"
TARGET_FOLDER="annotations"
COMMIT_MESSAGE="Added new JSON files with annotations"


mkdir -p "$REPO_DIR/$TARGET_FOLDER"

process_image() {
    local image_file="$1"
    local json_file="${image_file%.*}.json"
    local relative_path="${image_file#$ROOT_DIR/}"
    local target_dir="$REPO_DIR/$TARGET_FOLDER/$(dirname "$relative_path")"
    local target_json_file="$target_dir/$(basename $json_file)"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Check if JSON file exists and needs annotation
    if [ -f "$json_file" ]; then
        if jq -e '.Annotation."New Source" | contains("Ollama:'$MODEL_VERSION'")' "$json_file" > /dev/null 2>&1; then
            # Ensure the file in repo is up-to-date
            cp "$json_file" "$target_json_file"
            return
        else
            # Annotation needed for existing JSON file
            :
        fi
    else
        echo "No existing JSON file found for $image_file."
        return
    fi

    # Run Ollama only if needed
    local ollama_output=$(ollama run llava:${MODEL_VERSION} "describe $image_file" > /dev/null 2>&1)
    if [ $? -eq 0 ]; then
        # Annotate existing JSON file
        jq --arg version "Ollama:$MODEL_VERSION" --arg text "$ollama_output" \
           '.Annotation["New Source"] = $version | .Annotation.Test = $text' "$json_file" > tmp.$$ && mv tmp.$$ "$json_file"

        # Copy the updated JSON file to the target directory
        cp "$json_file" "$target_json_file"
    else
        echo "Failed to run Ollama on $image_file"
    fi
}

export -f process_image
export MODEL_VERSION
export REPO_DIR
export TARGET_FOLDER
export ROOT_DIR

# Infinite loop to continuously check for new images
while true; do
    # Find all JPG images in the directory and subdirectories and process each one
    find "$ROOT_DIR" -type f -iname "*.jpg" -exec bash -c 'process_image "$0"' {} \;

    # Change to the Git repository directory
    cd "$REPO_DIR"

    # Stage the new or updated JSON files
    #git add "$TARGET_FOLDER"/*.json

    # Commit the changes to the repository if there are any staged files
    if git diff-index --quiet HEAD --; then
        echo "No changes to commit."
    else
        git commit -m "$COMMIT_MESSAGE"
        git push origin main
    fi

    echo "All images from the batch processed and changes committed to the repository."


done
