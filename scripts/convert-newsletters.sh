#!/bin/bash
# Convert Bot Pod newsletter markdown files to Mintlify MDX format
# Usage: ./scripts/convert-newsletters.sh

set -e

BOTPOD_DIR="${HOME}/botpod"
OUTPUT_DIR="$(dirname "$0")/../podcast"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Episode metadata (episode_num:title:date:youtube_id)
declare -A EPISODES=(
    ["1"]="Trading Agents in Condor|April 4, 2026|O93R_ddB-8o"
    ["2"]="Building a Grid Scalping Agent|April 11, 2026|IolYm0zomJM"
    ["3"]="Creating Routines|April 17, 2026|OGaQJmrjWqA"
    ["4"]="Backtesting|April 24, 2026|xWJ8-s6njXY"
    ["5"]="Using Routines in Agents|May 1, 2026|5OCAAGz9XWg"
)

convert_newsletter() {
    local ep_num="$1"
    local newsletter_file="$2"
    local output_file="$3"

    # Parse episode metadata
    IFS='|' read -r title date youtube_id <<< "${EPISODES[$ep_num]}"

    # Read newsletter content
    local content
    content=$(cat "$newsletter_file")

    # Extract summary (first paragraph after the title)
    local description
    description=$(echo "$content" | sed -n '/^We.re back\|^We.re excited/,/^$/p' | head -1 | tr -d '\n' | cut -c1-160)
    if [ -z "$description" ]; then
        description="Episode $ep_num of The Bot Pod podcast"
    fi

    # Remove the original H1 title and full transcript section
    local body
    body=$(echo "$content" | sed '1d' | sed '/^## Full Transcript$/,$d')

    # Create MDX file with frontmatter
    cat > "$output_file" << EOF
---
title: "Episode $ep_num: $title"
description: "$description"
---

<Info>
**Watch on YouTube:** [Episode $ep_num](https://www.youtube.com/watch?v=$youtube_id)
**Air Date:** $date
</Info>

$body
EOF

    echo "Created: $output_file"
}

# Convert each episode
for ep_num in "${!EPISODES[@]}"; do
    newsletter_file="$BOTPOD_DIR/ep$ep_num/newsletter-ep$ep_num.md"
    output_file="$OUTPUT_DIR/ep$ep_num.mdx"

    if [ -f "$newsletter_file" ]; then
        convert_newsletter "$ep_num" "$newsletter_file" "$output_file"
    else
        echo "Warning: $newsletter_file not found"
    fi
done

echo ""
echo "Conversion complete. Files created in $OUTPUT_DIR"
echo "Remember to:"
echo "1. Review generated files for formatting issues"
echo "2. Add podcast pages to docs.json navigation"
