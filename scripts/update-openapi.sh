#!/bin/bash
# Update OpenAPI specs for Mintlify documentation
#
# Usage: ./scripts/update-openapi.sh
#
# This script processes OpenAPI files from the openapi-sources directory
# and copies them to the appropriate locations for Mintlify.
#
# To update the API docs:
# 1. Place updated OpenAPI files in openapi-sources/:
#    - openapi-sources/hummingbot-api.json (from Hummingbot API server)
#    - openapi-sources/gateway.json (from Gateway server)
# 2. Run this script
# 3. Commit and push changes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/openapi-sources"

echo "Updating OpenAPI specs..."

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Creating openapi-sources directory..."
    mkdir -p "$SOURCE_DIR"
    echo ""
    echo "Please add your OpenAPI files to openapi-sources/:"
    echo "  - hummingbot-api.json (from http://localhost:8000/openapi.json)"
    echo "  - gateway.json (from http://localhost:15888/docs/json)"
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
    echo "Skipping Hummingbot API (openapi-sources/hummingbot-api.json not found)"
fi

echo ""

# Process Gateway OpenAPI
if [ -f "$SOURCE_DIR/gateway.json" ]; then
    echo "Processing Gateway OpenAPI..."

    # Validate JSON
    if ! jq empty "$SOURCE_DIR/gateway.json" 2>/dev/null; then
        echo "Error: gateway.json is not valid JSON"
        exit 1
    fi

    # Ensure destination directory exists
    mkdir -p "$ROOT_DIR/gateway-reference"

    # Copy to destination
    cp "$SOURCE_DIR/gateway.json" "$ROOT_DIR/gateway-reference/openapi.json"

    # Show info
    VERSION=$(jq -r '.info.version // "unknown"' "$SOURCE_DIR/gateway.json")
    PATHS=$(jq '.paths | keys | length' "$SOURCE_DIR/gateway.json")
    echo "  Version: $VERSION"
    echo "  Endpoints: $PATHS"
    echo "  Copied to: gateway-reference/openapi.json"
else
    echo "Skipping Gateway (openapi-sources/gateway.json not found)"
fi

echo ""
echo "Done! Run 'mintlify dev' to preview changes."
