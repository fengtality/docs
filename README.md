# Hummingbot API Documentation

Documentation site for [Hummingbot API](https://github.com/hummingbot/hummingbot-api) and [Gateway](https://github.com/hummingbot/gateway), built with [Mintlify](https://mintlify.com).

## Repository Structure

```
docs/
├── docs.json                    # Mintlify config (navigation, theme, OpenAPI settings)
├── docs.mdx                     # Homepage
├── api-reference.mdx            # API Reference overview page
├── gateway-reference.mdx        # Gateway Reference overview page
│
├── docs/                        # Documentation pages
│   ├── installation.mdx
│   ├── quickstart.mdx
│   └── gateway-setup.mdx
│
├── api-reference/               # Hummingbot API OpenAPI spec
│   └── openapi.json             # → copied from openapi-sources/hummingbot-api.json
│
├── gateway-reference/           # Gateway OpenAPI spec
│   └── openapi.json             # → processed from openapi-sources/gateway.json
│
├── openapi-sources/             # Raw OpenAPI specs from source servers
│   ├── hummingbot-api.json      # Raw spec from Hummingbot API
│   └── gateway.json             # Raw spec from Gateway
│
├── scripts/                     # Build and maintenance scripts
│   ├── generate-openapi.sh      # Fetch specs from running servers
│   ├── update-openapi.sh        # Process and copy specs from openapi-sources/
│   └── process-openapi.js       # Post-process Gateway spec for Mintlify
│
├── images/                      # Documentation images
└── logo/                        # Site logos
```

## Local Development

### Prerequisites

- Node.js 18+
- [Mintlify CLI](https://www.npmjs.com/package/mintlify)

### Install Mintlify CLI

```bash
npm i -g mintlify
```

### Start Local Preview

```bash
mintlify dev
```

View at http://localhost:3000

## Updating OpenAPI Specs

The API Reference and Gateway Reference are generated from OpenAPI specifications. There are two methods to update them:

### Method 1: Automatic (Recommended)

Fetches specs directly from running servers:

```bash
# Start the source servers first
cd ~/hummingbot-api && make run        # Starts at localhost:8000
cd ~/gateway && pnpm start --dev       # Starts at localhost:15888

# Generate and process specs
./scripts/generate-openapi.sh

# Or update only one:
./scripts/generate-openapi.sh --api-only
./scripts/generate-openapi.sh --gateway-only
```

### Method 2: Manual

If you already have the OpenAPI JSON files:

1. Place files in `openapi-sources/`:
   - `hummingbot-api.json` - from `http://localhost:8000/openapi.json`
   - `gateway.json` - from `http://localhost:15888/docs/json`

2. Run the update script:
   ```bash
   ./scripts/update-openapi.sh
   ```

### What the Scripts Do

1. **Hummingbot API** (`api-reference/openapi.json`):
   - Copied directly from source (no processing needed)
   - The API server already generates clean operationIds and summaries

2. **Gateway** (`gateway-reference/openapi.json`):
   - Processed by `process-openapi.js` which:
     - Adds `operationId` fields for clean URL paths
     - Adds `summary` fields for sidebar titles
     - Converts `anyOf` with null to `nullable: true` (Mintlify compatibility)

### After Updating

1. Run `mintlify dev` to preview changes
2. Verify sidebar titles and URL paths look correct
3. Commit all changes including both `openapi-sources/` and processed files

## Troubleshooting

### Dev server not starting
```bash
mintlify update  # Update CLI to latest version
```

### 404 on pages
Ensure you're running `mintlify dev` in the directory containing `docs.json`.

### Gateway sidebar shows ugly URLs
Re-run `./scripts/generate-openapi.sh --gateway-only` to regenerate with proper operationIds.

## Publishing

Changes pushed to the main branch are automatically deployed via Mintlify's GitHub integration.

## Resources

- [Mintlify Documentation](https://mintlify.com/docs)
- [Hummingbot API Repository](https://github.com/hummingbot/hummingbot-api)
- [Gateway Repository](https://github.com/hummingbot/gateway)
