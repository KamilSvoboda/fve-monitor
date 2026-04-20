#!/bin/bash

URL="http://192.168.0.11/api/status/powerflow"
MAX_POWER=6000
INTERVAL=3

# ANSI barvy
GREEN="\033[32m"   # spotřeba
YELLOW="\033[38;5;214m"        # export do sítě (zlatá)
RED="\033[31m"     # import
GRAY="\033[90m"    # nevyužitá kapacita
RESET="\033[0m"

draw_bar() {
    local pv_w=$1
    local load_w=$2
    local grid_w=$3

    load_w=${load_w#-}
    pv_w=${pv_w:-0}
    load_w=${load_w:-0}
    grid_w=${grid_w:-0}

    pv_kw=$(awk "BEGIN {printf \"%.2f\", $pv_w/1000}")
    load_kw=$(awk "BEGIN {printf \"%.2f\", $load_w/1000}")
    grid_kw=$(awk "BEGIN {printf \"%.2f\", $grid_w/1000}")

    cols=$(tput cols 2>/dev/null)
    cols=${cols:-100}

    fixed_width=35
    BAR_WIDTH=$((cols - fixed_width))
    (( BAR_WIDTH < 10 )) && BAR_WIDTH=10
    (( BAR_WIDTH > 120 )) && BAR_WIDTH=120

    pv_len=$(awk "BEGIN {printf \"%d\", ($pv_w/$MAX_POWER)*$BAR_WIDTH}")
    load_len=$(awk "BEGIN {printf \"%d\", ($load_w/$MAX_POWER)*$BAR_WIDTH}")
    (( load_len > pv_len )) && load_len=$pv_len

    export_len=$((pv_len - load_len))
    empty_len=$((BAR_WIDTH - pv_len))

    load_bar=$(printf "%0.s█" $(seq 1 $load_len))
    export_bar=$(printf "%0.s█" $(seq 1 $export_len))
    empty_bar=$(printf "%0.s░" $(seq 1 $empty_len))

    # barva pro grid: záporné = export žlutě, kladné = import červeně
    if (( $(awk "BEGIN {print ($grid_w<0)}") )); then
        grid_color=$YELLOW
    else
        grid_color=$RED
    fi

    # výpis s obarvenou spotřebovanou částí
    printf "[%b%s%b%b%s%b%b%s%b] %s/%b%s%b/%b%s%b\n" \
        "$GREEN" "$load_bar" "$RESET" \
        "$grid_color" "$export_bar" "$RESET" \
        "$GRAY" "$empty_bar" "$RESET" \
        "$pv_kw" "$GREEN" "$load_kw" "$RESET" \
        "$grid_color" "$grid_kw" "$RESET"
}

echo "Monitoring FVE (Ctrl+C pro ukončení)"
echo "Formát: graf  P/L/G (kW) - spotřeba zeleně"
echo

while true; do
    response=$(curl -s "$URL")

    if [ -n "$response" ]; then
        pv=$(echo "$response" | jq -r '.site.P_PV // 0')
        load=$(echo "$response" | jq -r '.site.P_Load // 0')
        grid=$(echo "$response" | jq -r '.site.P_Grid // 0')

        draw_bar "$pv" "$load" "$grid"
    else
        echo "Chyba načtení..."
    fi

    sleep $INTERVAL
done