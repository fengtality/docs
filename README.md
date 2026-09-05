# Condor Documentation

Documentation site for [Condor](https://github.com/hummingbot/condor), published at [condor.hummingbot.org](https://condor.hummingbot.org) and built with [Mintlify](https://mintlify.com). Also hosts the [Hummingbot API](https://github.com/hummingbot/hummingbot-api) and [Gateway](https://github.com/hummingbot/gateway) reference sections.

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

## Previewing these docs locally

**There is no preview link on pull requests.** Mintlify only builds those on its Pro and
Enterprise plans, so the local preview below is how you see your work before it merges —
and how a reviewer sees it. It needs no Mintlify account.

### Prerequisites

- Node.js 18+
- Nothing else — `npx` fetches the CLI on demand

### Preview

From the repository root, the directory containing `docs.json`:

```bash
npx mint@latest dev
```

View at http://localhost:3000. The page reloads as you edit, and `--port 3001` moves it if
something already holds 3000. The CLI also prints a LAN address, which reaches someone on
the same network but nobody else.

> The CLI was renamed: it is `mint`, not `mintlify`. Older instructions saying
> `npm i -g mintlify` still work by installing a deprecated package. `npx mint@latest`
> always fetches the current version, so there is nothing to install or keep updated.

### Check it before you push

```bash
npx mint@latest validate       # docs.json, navigation paths, frontmatter
npx mint@latest broken-links   # every internal link and anchor
```

Both are quick, and between them they catch the two things that actually break a docs
build: a page missing from `docs.json`, and a link to a heading that was renamed.

### Reviewing someone else's branch

```bash
git fetch origin && git checkout <branch>
npx mint@latest dev
```

> Search is inactive locally until you run `mint login` — the CLI says so on startup.
> Everything else renders exactly as it will in production.

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

1. Run `npx mint@latest dev` to preview changes
2. Verify sidebar titles and URL paths look correct
3. Commit all changes including both `openapi-sources/` and processed files

## Troubleshooting

### Dev server not starting
```bash
npx mint@latest dev   # `npx ... @latest` always fetches the current CLI
```

### 404 on pages
Ensure you're running `npx mint@latest dev` in the directory containing `docs.json`.

### Gateway sidebar shows ugly URLs
Re-run `./scripts/generate-openapi.sh --gateway-only` to regenerate with proper operationIds.

## Publishing

Changes pushed to the main branch are automatically deployed via Mintlify's GitHub integration.

## Resources

- [Mintlify Documentation](https://mintlify.com/docs)
- [Hummingbot API Repository](https://github.com/hummingbot/hummingbot-api)
- [Gateway Repository](https://github.com/hummingbot/gateway)
