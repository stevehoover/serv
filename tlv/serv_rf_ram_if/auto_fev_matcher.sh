#!/bin/bash

# FEV Bit-Level Matching Auto-Detection and Suggestion Script
# Usage: ./auto_fev_matcher.sh <fev_output_file>

FEV_OUTPUT="$1"
if [[ ! -f "$FEV_OUTPUT" ]]; then
    echo "Usage: $0 <fev_output_file>"
    exit 1
fi

# Function to extract signal name and bits from FEV output
extract_signal_bits() {
    local pattern="$1"
    local section="$2"
    
    # Extract signal bits from patterns like "rcnt[0]", "rcnt[1]", etc.
    grep -A 20 "$section" "$FEV_OUTPUT" | \
    grep "$pattern" | \
    sed -n 's/.*\([a-zA-Z_][a-zA-Z0-9_]*\)\[\([0-9]\+\)\].*/\1[\2]/p' | \
    sort
}

# Function to extract base signal name
extract_base_signal() {
    echo "$1" | sed 's/\[.*\]//'
}

# Check if this looks like a register-to-pipesignal conversion issue
detect_register_pipesignal_pattern() {
    # Look for Gold internal signals with bit indices
    GOLD_BITS=$(extract_signal_bits "" "Gold internal:")
    
    # Look for Gate internal signals with DEFAULT_*_a0 pattern  
    GATE_BITS=$(extract_signal_bits "DEFAULT_.*_a0" "Gate internal:")
    
    if [[ -n "$GOLD_BITS" && -n "$GATE_BITS" ]]; then
        echo "DETECTED: Register-to-pipesignal bit-level matching pattern"
        
        # Extract base signal name (assume first signal)
        BASE_SIGNAL=$(echo "$GOLD_BITS" | head -1 | extract_base_signal)
        
        echo "Base signal: $BASE_SIGNAL"
        echo "Gold bits: $GOLD_BITS"
        echo "Gate bits: $GATE_BITS"
        
        # Generate suggested matches for incremental FEV
        echo ""
        echo "=== SUGGESTED MATCHES FOR fev.eqy ==="
        echo "[match $(basename $(pwd) | sed 's/.*_//')] # Adjust module name as needed"
        
        # For each gold bit, find corresponding gate bit
        while IFS= read -r gold_bit; do
            bit_num=$(echo "$gold_bit" | sed 's/.*\[\([0-9]\+\)\].*/\1/')
            echo "gold-match $gold_bit DEFAULT_${BASE_SIGNAL}_a0[$bit_num]"
        done <<< "$GOLD_BITS"
        
        echo ""
        echo "=== SUGGESTED MATCHES FOR fev_full*.eqy ==="
        echo "gold-match $BASE_SIGNAL |default<>0\$$BASE_SIGNAL"
        
        return 0
    fi
    
    return 1
}

# Main execution
if detect_register_pipesignal_pattern; then
    echo ""
    echo "=== EXPLANATION ==="
    echo "This failure pattern occurs when:"
    echo "1. Verilog registers are converted to TL-Verilog pipesignals"
    echo "2. Incremental FEV uses 'splitnets -ports' which splits vectors into bits"
    echo "3. Full FEV keeps vectors intact"
    echo "4. Missing bits in gold model require careful bit-by-bit matching"
    echo ""
    echo "Apply the suggested matches above to resolve the FEV failures."
else
    echo "No register-to-pipesignal bit-level matching pattern detected."
    echo "This appears to be a different type of FEV failure."
fi