#!/bin/bash
# Generate SVG and PNG files from all PlantUML diagrams
# Usage: ./generate-diagrams.sh [docker|local|auto]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Determine rendering method
METHOD="${1:-auto}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== PlantUML Diagram Generator ===${NC}"
echo -e "${BLUE}    Centralized Logging Docs      ${NC}"
echo ""

# Find all .puml files
shopt -s nullglob
PUML_FILES=(*.puml)
shopt -u nullglob

if [ ${#PUML_FILES[@]} -eq 0 ]; then
    echo -e "${RED}No .puml files found in $SCRIPT_DIR${NC}"
    exit 1
fi

echo "Found ${#PUML_FILES[@]} PlantUML diagram(s):"
for file in "${PUML_FILES[@]}"; do
    echo "  - $file"
done
echo ""

# Auto-detect method if not specified
if [ "$METHOD" = "auto" ]; then
    if command -v plantuml &> /dev/null; then
        METHOD="local"
    elif command -v docker &> /dev/null; then
        METHOD="docker"
    else
        echo -e "${YELLOW}Warning: Neither plantuml nor docker found${NC}"
        echo "Please install one of:"
        echo "  - PlantUML: brew install plantuml"
        echo "  - Docker: brew install docker"
        exit 1
    fi
fi

echo -e "Rendering method: ${GREEN}${METHOD}${NC}"
echo ""

# Generate diagrams based on method
case "$METHOD" in
    local)
        echo "Using local plantuml installation..."
        echo ""
        
        # Generate SVG files
        echo -e "${BLUE}Generating SVG files...${NC}"
        plantuml -tsvg "${PUML_FILES[@]}"
        echo -e "${GREEN}✓ SVG generation complete${NC}"
        echo ""
        
        # Generate PNG files
        echo -e "${BLUE}Generating PNG files...${NC}"
        plantuml -tpng "${PUML_FILES[@]}"
        echo -e "${GREEN}✓ PNG generation complete${NC}"
        echo ""
        ;;
        
    docker)
        echo "Using Docker plantuml image..."
        echo ""
        
        # Generate SVG files
        echo -e "${BLUE}Generating SVG files...${NC}"
        docker run --rm -v "$(pwd):/data" plantuml/plantuml:latest -tsvg /data/*.puml
        echo -e "${GREEN}✓ SVG generation complete${NC}"
        echo ""
        
        # Generate PNG files
        echo -e "${BLUE}Generating PNG files...${NC}"
        docker run --rm -v "$(pwd):/data" plantuml/plantuml:latest -tpng /data/*.puml
        echo -e "${GREEN}✓ PNG generation complete${NC}"
        echo ""
        ;;
        
    *)
        echo -e "${RED}Unknown method: $METHOD${NC}"
        echo "Usage: $0 [docker|local|auto]"
        exit 1
        ;;
esac

# List generated files
echo -e "${BLUE}=== Generated Files ===${NC}"
echo ""

for puml in "${PUML_FILES[@]}"; do
    base="${puml%.puml}"
    echo -e "${GREEN}${puml}${NC}"
    if [ -f "${base}.svg" ]; then
        size=$(ls -lh "${base}.svg" | awk '{print $5}')
        echo "  ├── ${base}.svg (${size})"
    fi
    if [ -f "${base}.png" ]; then
        size=$(ls -lh "${base}.png" | awk '{print $5}')
        echo "  └── ${base}.png (${size})"
    fi
    echo ""
done

echo -e "${GREEN}✓ All diagrams generated successfully!${NC}"
echo ""
echo "Generated diagrams:"
echo "  - mobility-collector-architecture.{svg,png}"
echo "  - centralized-monitoring-flow.{svg,png}"
echo "  - metrics-export-detailed.{svg,png}"
echo ""
echo "Tip: Run 'git add *.svg *.png' to stage generated images for commit"
