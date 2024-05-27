#!/bin/bash

ROOT_DIR="/home/milosz/Downloads/m"
MODEL_VERSION="7b"
REPO_DIR="/home/milosz/EMLI12"
TARGET_FOLDER="annotations"
COMMIT_MESSAGE="Update and standardize annotations in JSON files"
SLEEP_INTERVAL=5

mkdir -p "$REPO_DIR/$TARGET_FOLDER"

process_image() {
    local image_file="$1"
    local json_file="${image_file%.*}.json"
    local relative_path="${image_file#$ROOT_DIR/}"
    local target_dir="$REPO_DIR/$TARGET_FOLDER/$(dirname "$relative_path")"
    local target_json_file="$target_dir/$(basename $json_file)"

    # echo "Processing image: $image_file"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Check for existance and annotation
    if [ -f "$json_file" ]; then
        # echo "Found existing JSON file: $json_file"
        if jq -e '.Annotation."New Source" | contains("Ollama:'$MODEL_VERSION'")' "$json_file" > /dev/null 2>&1; then
            # echo "Skipping $image_file; JSON file already annotated."
            cp "$json_file" "$target_json_file"
            return
        else
            # echo "Annotation needed for existing JSON file: $json_file"
            :
        fi
    else
        echo "No existing JSON file found for $image_file."
        return
    fi

    # Annotation Process
    local ollama_output=$(ollama run llava:${MODEL_VERSION} "describe $image_file")
    if [ $? -eq 0 ]; then
        # Annotate existing JSON file
        jq --arg version "Ollama:$MODEL_VERSION" --arg text "$ollama_output" \
           '.Annotation["New Source"] = $version | .Annotation.Test = $text' "$json_file" > tmp.$$ && mv tmp.$$ "$json_file"
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

while true; do
    # Looking for every JPG and processing
    find "$ROOT_DIR" -type f -iname "*.jpg" -exec bash -c 'process_image "$0"' {} \;

    
    cd "$REPO_DIR"

    find "$TARGET_FOLDER" -type f -name "*.json"

    # Stage the new or updated JSON files
    git add "$TARGET_FOLDER"/*.json

    # Commit the changes to the repo
    if git diff-index --quiet HEAD --; then
        echo "No changes to commit."
    else
        git commit -m "$COMMIT_MESSAGE"
        git push origin main
    fi

     echo "All images processed and changes committed to the repository."

    # Wait and check again
    sleep $SLEEP_INTERVAL
done
