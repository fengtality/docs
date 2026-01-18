#!/bin/bash
# Generate and update OpenAPI specs from source repositories
#
# Usage: ./scripts/generate-openapi.sh [--api-only] [--gateway-only]
#
# This script:
# 1. Starts the Hummingbot API and Gateway servers if not running
# 2. Fetches fresh OpenAPI specs from both servers
# 3. Processes them for Mintlify compatibility
# 4. Copies them to the appropriate locations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="$ROOT_DIR/openapi-sources"

# Repository paths
HUMMINGBOT_API_DIR="$HOME/hummingbot-api"
GATEWAY_DIR="$HOME/gateway"

# Server URLs
API_URL="http://localhost:8000"
GATEWAY_URL="http://localhost:15888"

# Parse arguments
API_ONLY=false
GATEWAY_ONLY=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --api-only) API_ONLY=true; shift ;;
        --gateway-only) GATEWAY_ONLY=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Create source directory
mkdir -p "$SOURCE_DIR"

# Function to check if a server is running
check_server() {
    local url=$1
    curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null | grep -q "200\|401\|403"
}

# Function to wait for server
wait_for_server() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=0

    echo "Waiting for $name to be ready..."
    while ! check_server "$url"; do
        attempt=$((attempt + 1))
        if [ $attempt -ge $max_attempts ]; then
            echo "Error: $name did not become ready"
            return 1
        fi
        sleep 2
    done
    echo "$name is ready"
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

    # Copy to destination
    cp "$SOURCE_DIR/hummingbot-api.json" "$ROOT_DIR/api-reference/openapi.json"

    # Show info
    VERSION=$(jq -r '.info.version // "unknown"' "$SOURCE_DIR/hummingbot-api.json")
    PATHS=$(jq '.paths | keys | length' "$SOURCE_DIR/hummingbot-api.json")
    echo "  Version: $VERSION"
    echo "  Endpoints: $PATHS"
    echo "  Saved to: api-reference/openapi.json"
}

# Generate Gateway spec
generate_gateway_spec() {
    echo ""
    echo "=== Generating Gateway OpenAPI spec ==="

    # Check if server is running
    if ! check_server "$GATEWAY_URL"; then
        echo "Gateway server not running at $GATEWAY_URL"
        echo "Please start it with: cd $GATEWAY_DIR && pnpm start --dev"
        return 1
    fi

    # Fetch OpenAPI spec
    echo "Fetching OpenAPI spec from $GATEWAY_URL/docs/json..."
    curl -s "$GATEWAY_URL/docs/json" > "$SOURCE_DIR/gateway.json"

    # Validate JSON
    if ! jq empty "$SOURCE_DIR/gateway.json" 2>/dev/null; then
        echo "Error: Failed to fetch valid JSON from Gateway"
        cat "$SOURCE_DIR/gateway.json"
        return 1
    fi

    # Ensure destination directory exists
    mkdir -p "$ROOT_DIR/gateway-reference"

    # Process for Mintlify compatibility (convert anyOf with null to nullable)
    node "$SCRIPT_DIR/process-openapi.js" "$SOURCE_DIR/gateway.json" > "$ROOT_DIR/gateway-reference/openapi.json"

    # Show info
    VERSION=$(jq -r '.info.version // "unknown"' "$SOURCE_DIR/gateway.json")
    PATHS=$(jq '.paths | keys | length' "$SOURCE_DIR/gateway.json")
    echo "  Version: $VERSION"
    echo "  Endpoints: $PATHS"
    echo "  Processed and saved to: gateway-reference/openapi.json"
}

echo "OpenAPI Spec Generator"
echo "======================"

if [ "$GATEWAY_ONLY" = false ]; then
    generate_api_spec || echo "Warning: Failed to generate Hummingbot API spec"
fi

if [ "$API_ONLY" = false ]; then
    generate_gateway_spec || echo "Warning: Failed to generate Gateway spec"
fi

echo ""
echo "Done! Run 'mintlify dev' to preview changes."
