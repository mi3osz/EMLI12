#!/bin/bash

# Define the root directory to start scanning from
ROOT_DIR="/home/milosz/Downloads/m"
MODEL_VERSION="7b" # This is the model version of Ollama used

# Function to process an image
process_image() {
    local image_file="$1"
    local json_file="${image_file%.*}.json"

    # Run Ollama on the image and capture the output
    local ollama_output=$(ollama run llava:${MODEL_VERSION} "describe $image_file")

    # Check if Ollama ran successfully
    if [ $? -eq 0 ]; then
        # Check if JSON file already exists
        if [ -f "$json_file" ]; then
            # Existing JSON file, append new annotation
            # Use `jq` to add new data without replacing old data
            jq --arg text "$ollama_output" '.Annotation += {"New Source": "Ollama:'$MODEL_VERSION'", "Test": $text}' "$json_file" > tmp.$$ && mv tmp.$$ "$json_file"
        else
            # No existing JSON file, create new
            echo "{
  \"File Name\": \"$(basename $image_file)\",
  \"Annotation\": {
    \"Source\": \"Ollama:${MODEL_VERSION}\",
    \"Test\": \"$ollama_output\"
  }
}" > "$json_file"
        fi
        echo "JSON file updated successfully at $json_file"
    else
        echo "Failed to run Ollama on $image_file"
    fi
}

# Export the function so it can be used in subshells
export -f process_image
export MODEL_VERSION

# Find all JPG images in the directory and subdirectories and process each one
find "$ROOT_DIR" -type f -iname "*.jpg" -exec bash -c 'process_image "$0"' {} \;

echo "All images processed."
