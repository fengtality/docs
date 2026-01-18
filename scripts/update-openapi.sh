#!/bin/bash
# Update OpenAPI spec for Mintlify documentation
#
# Usage: ./scripts/update-openapi.sh
#
# This script processes the OpenAPI file from the openapi-sources directory
# and copies it to the appropriate location for Mintlify.
#
# To update the API docs:
# 1. Place updated OpenAPI file in openapi-sources/hummingbot-api.json
# 2. Run this script
# 3. Commit and push changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/openapi-sources"

echo "Updating OpenAPI spec..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Creating openapi-sources directory..."
    mkdir -p "$SOURCE_DIR"
    echo ""
    echo "Please add your OpenAPI file to openapi-sources/:"
    echo "  - hummingbot-api.json (from http://localhost:8000/openapi.json)"
    echo ""
    exit 1
fi

# Process Hummingbot API OpenAPI
if [ -f "$SOURCE_DIR/hummingbot-api.json" ]; then
    echo "Processing Hummingbot API OpenAPI..."

    # Validate JSON
    if ! jq empty "$SOURCE_DIR/hummingbot-api.json" 2>/dev/null; then
        echo "Error: hummingbot-api.json is not valid JSON"
        exit 1
    fi

    # Copy to destination
    cp "$SOURCE_DIR/hummingbot-api.json" "$ROOT_DIR/api-reference/openapi.json"

    # Show info
    VERSION=$(jq -r '.info.version // "unknown"' "$SOURCE_DIR/hummingbot-api.json")
    PATHS=$(jq '.paths | keys | length' "$SOURCE_DIR/hummingbot-api.json")
    echo "  Version: $VERSION"
    echo "  Endpoints: $PATHS"
    echo "  Copied to: api-reference/openapi.json"
else
    echo "Error: openapi-sources/hummingbot-api.json not found"
    exit 1
fi

echo ""
echo "Done! Run 'mintlify dev' to preview changes."
