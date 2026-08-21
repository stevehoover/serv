#!/bin/bash

# Automated Verilog -> TL-Verilog conversion launcher
# Usage: ./convert.sh <module_name>
# Example: ./convert.sh serv_ctrl

set -e

MODULE="$1"

if [ -z "$MODULE" ]; then
    echo "Usage: ./convert.sh <module_name>"
    exit 1
fi

if [ ! -f "tlv/$MODULE/orig.sv" ]; then
    echo "Error: tlv/$MODULE/orig.sv not found"
    echo "Create the module directory and copy orig.sv first"
    exit 1
fi

if [ ! -f "$HOME/.anthropic/key.txt" ]; then
    echo "Error: Anthropic API key not found at $HOME/.anthropic/key.txt"
    exit 1
fi

echo "Starting conversion of $MODULE..."
echo "Using Docker + Claude Code non-interactive mode"
echo ""

cd tlv/env

docker compose run --rm \
    -e ANTHROPIC_API_KEY="$(cat "$HOME/.anthropic/key.txt")" \
    claude-conversion \
    bash -lc "
        cd /workspace/proj/stevehoover-serv/tlv &&
        claude -p \"Follow the instructions in /workspace/proj/stevehoover-serv/tlv/project_instructions/desktop_agent_instructions.md to convert $MODULE from Verilog to TL-Verilog.\"
    "
