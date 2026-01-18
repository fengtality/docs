# Condor & Hummingbot API Documentation

## Working relationship
- You can push back on ideas - this can lead to better documentation. Cite sources and explain your reasoning when you do so
- ALWAYS ask for clarification rather than making assumptions
- NEVER lie, guess, or make up information

## Project context

This documentation covers **Condor** (Telegram interface) and **Hummingbot API** (backend server). It is a focused subset of the main Hummingbot documentation, not a complete replacement.

### Source repositories
- **Condor**: https://github.com/hummingbot/condor
- **Hummingbot API**: https://github.com/hummingbot/hummingbot-api
- **API Client**: https://github.com/hummingbot/hummingbot-api-client

### Reference documentation
- Main Hummingbot docs: `~/hummingbot-site`
- Relevant sections: `docs/condor/`, `docs/hummingbot-api/`, `docs/mcp/`, `docs/gateway/`

### Tech stack
- Format: MDX files with YAML frontmatter
- Config: `docs.json` for navigation, theme, settings
- Framework: Mintlify
- Components: Mintlify components (Cards, Tabs, Accordions, etc.)

## Architecture overview

```
Telegram User
     |
  Condor Bot (Telegram interface)
     |
     +---> Hummingbot API (FastAPI server)
     |          |
     |          +---> PostgreSQL (trading data)
     |          +---> EMQX (message broker for bots)
     |          +---> Exchange connectors (CEX trading)
     |
     +---> Gateway (DEX trading via Uniswap, Jupiter, etc.)
```

### Key concepts
- **Condor**: Telegram bot providing mobile-friendly interface to Hummingbot infrastructure
- **Hummingbot API**: RESTful API for managing trading operations, bot orchestration, and exchange connectivity
- **Gateway**: Separate service for DEX trading (swaps, liquidity pools)
- **Controllers**: Trading strategy components running inside bot instances

## Repository structure

```
docs/
├── docs.json                    # Mintlify config (navigation, theme, OpenAPI)
├── docs.mdx                     # Homepage
├── api-reference.mdx            # API Reference overview
├── docs/                        # Documentation pages (MDX)
├── api-reference/openapi.json   # Hummingbot API spec
├── openapi-sources/             # Raw specs from source servers
└── scripts/                     # Build scripts
```

## OpenAPI spec maintenance

The API Reference is auto-generated from the OpenAPI spec. When endpoints change in the source repo, regenerate the spec:

### Quick update (server already running)

```bash
./scripts/generate-openapi.sh
```

### Full update workflow

1. Start the Hummingbot API server:
   ```bash
   cd ~/hummingbot-api && make run        # localhost:8000
   ```

2. Generate spec:
   ```bash
   ./scripts/generate-openapi.sh
   ```

3. Preview and verify:
   ```bash
   mintlify dev
   ```

4. Commit both `openapi-sources/hummingbot-api.json` and `api-reference/openapi.json`

### Fixing issues

If changes to router docstrings aren't appearing:
1. Ensure docstrings are description-only (no Args/Returns/Raises sections)
2. Restart the source server
3. Re-fetch the spec

## Content strategy
- Document just enough for user success - not too much, not too little
- Prioritize accuracy and usability of information
- Make content evergreen when possible
- Search `~/hummingbot-site` for existing information before adding new content
- Check existing patterns in this repo for consistency
- Start by making the smallest reasonable changes

## Frontmatter requirements

Every MDX file must include:

```yaml
---
title: "Clear, descriptive page title"
description: "Concise summary for SEO/navigation (1-2 sentences)"
---
```

## Writing standards
- Second-person voice ("you")
- Prerequisites at start of procedural content
- Test all code examples before publishing
- Match style and formatting of existing pages
- Include both basic and advanced use cases where relevant
- Language tags on all code blocks (```bash, ```python, ```yaml, etc.)
- Alt text on all images
- Relative paths for internal links

## Git workflow
- NEVER use `--no-verify` when committing
- Ask how to handle uncommitted changes before starting
- Create a new branch when no clear branch exists for changes
- Commit frequently throughout development
- NEVER skip or disable pre-commit hooks

## Do not
- Skip frontmatter on any MDX file
- Use absolute URLs for internal links
- Include untested code examples
- Make assumptions - always ask for clarification
- Duplicate content from `~/hummingbot-site` unless strategically necessary
- Add fallback values or mock data - throw clear errors instead

## Mintlify dev server
```bash
# Start local preview
mintlify dev

# Available at http://localhost:3000
```

## Common documentation patterns

### Installation guides
1. Prerequisites section first
2. Docker method (recommended) before source method
3. Environment configuration
4. Verification steps

### Command/feature documentation
1. Brief description
2. Supported options/exchanges
3. Step-by-step usage
4. Code examples
5. Common issues/troubleshooting (if needed)

### API endpoint documentation
- Use Mintlify's OpenAPI integration where possible
- Include request/response examples
- Document authentication requirements
