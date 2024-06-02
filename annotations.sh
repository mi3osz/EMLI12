#!/bin/bash

ROOT_DIR="/home/milosz/Downloads/ma"
MODEL_VERSION="7b"
REPO_DIR="/home/milosz/EMLI12"
TARGET_FOLDER="annotations"
COMMIT_MESSAGE="Added new JSON files with annotations"

mkdir -p "$REPO_DIR/$TARGET_FOLDER"

process_image() {
    local image_file="$1"
    local json_file="${image_file%.*}.json"
    local relative_path="${image_file#$ROOT_DIR/}"
    local target_dir="$REPO_DIR/$TARGET_FOLDER/$(dirname "$relative_path")"
    local target_json_file="$target_dir/$(basename $json_file)"

    # echo "Processing image: $image_file"

    # Create target directory
    mkdir -p "$target_dir"

    # Check before annotating
    if [ -f "$json_file" ]; then
        # echo "Found existing JSON file: $json_file"
        if jq -e '.Annotation."Source" | contains("Ollama:'$MODEL_VERSION'")' "$json_file" > /dev/null 2>&1; then
            # echo "Skipping $image_file"
            # copy so file is up to date
            cp "$json_file" "$target_json_file"
            return
        else
            echo "Annotation needed for existing JSON file: $json_file"
            :
        fi
    else
        echo "No existing JSON file found for $image_file."
        return
    fi

  
    local ollama_output=$(ollama run llava:${MODEL_VERSION} "describe $image_file")
    if [ $? -eq 0 ]; then
        # Annotate existing JSON file
        jq --arg version "Ollama:$MODEL_VERSION" --arg text "$ollama_output" \
           '.Annotation["Source"] = $version | .Annotation.Test = $text' "$json_file" > tmp.$$ && mv tmp.$$ "$json_file"

        # Copy the JSON to git repository
        cp "$json_file" "$target_json_file"
        # echo "JSON file updated successfully at $json_file and $target_json_file"
    else
        echo "Failed to run Ollama on $image_file"
    fi
}

export -f process_image
export MODEL_VERSION
export REPO_DIR
export TARGET_FOLDER
export ROOT_DIR

# Continuously check for new images
while true; do
    # Find all JPG images to add annotations
    find "$ROOT_DIR" -type f -iname "*.jpg" -exec bash -c 'process_image "$0"' {} \;

    # Change to the git repository directory
    cd "$REPO_DIR"

    # echo "Listing JSON files in $TARGET_FOLDER:"
    # find "$TARGET_FOLDER" -type f -name "*.json"

    # Stage the JSONs
    git add "$TARGET_FOLDER"/*.json

    # Commit the changes to the repository, if there were any
    if git diff-index --quiet HEAD --; then
        echo "No changes to commit."
    else
        git commit -m "$COMMIT_MESSAGE"
        git push origin main
    fi

     echo "All images from the batch processed and changes committed to the repository."

done
