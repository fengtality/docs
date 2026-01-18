#!/bin/bash
# Generate and update OpenAPI spec from Hummingbot API
#
# Usage: ./scripts/generate-openapi.sh
#
# This script:
# 1. Fetches fresh OpenAPI spec from the Hummingbot API server
# 2. Adds servers field for Mintlify API playground base URL
# 3. Saves to api-reference/openapi.json

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/openapi-sources"

# Repository path
HUMMINGBOT_API_DIR="$HOME/hummingbot-api"

# Server URL
API_URL="http://localhost:8000"

# Create source directory
mkdir -p "$SOURCE_DIR"

# Function to check if a server is running
check_server() {
    local url=$1
    curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200\|401\|403"
}

# Generate Hummingbot API spec
generate_api_spec() {
    echo ""
    echo "=== Generating Hummingbot API OpenAPI spec ==="

    # Check if server is running
    if ! check_server "$API_URL"; then
        echo "Hummingbot API server not running at $API_URL"
        echo "Please start it with: cd $HUMMINGBOT_API_DIR && make run"
        return 1
    fi

    # Fetch OpenAPI spec
    echo "Fetching OpenAPI spec from $API_URL/openapi.json..."
    curl -s -u admin:admin "$API_URL/openapi.json" > "$SOURCE_DIR/hummingbot-api.json"

    # Validate JSON
    if ! jq empty "$SOURCE_DIR/hummingbot-api.json" 2>/dev/null; then
        echo "Error: Failed to fetch valid JSON from Hummingbot API"
        cat "$SOURCE_DIR/hummingbot-api.json"
        return 1
    fi

    # Add servers field for Mintlify (required for API playground base URL)
    jq '. + {servers: [{url: "http://localhost:8000", description: "Local development server"}]}' \
        "$SOURCE_DIR/hummingbot-api.json" > "$ROOT_DIR/api-reference/openapi.json"

    # Show info
    VERSION=$(jq -r '.info.version // "unknown"' "$SOURCE_DIR/hummingbot-api.json")
    PATHS=$(jq '.paths | keys | length' "$SOURCE_DIR/hummingbot-api.json")
    echo "  Version: $VERSION"
    echo "  Endpoints: $PATHS"
    echo "  Saved to: api-reference/openapi.json"
}

echo "OpenAPI Spec Generator"
echo "======================"

generate_api_spec || echo "Warning: Failed to generate Hummingbot API spec"

echo ""
echo "Done! Run 'mintlify dev' to preview changes."
