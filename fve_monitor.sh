#!/bin/bash

URL="http://192.168.0.11/api/status/powerflow"
MAX_POWER=6000
INTERVAL=3
BAR_CELLS=60
CELL_POWER=$((MAX_POWER / BAR_CELLS))
FILLED_CHAR="▋"
EMPTY_CHAR="░"

# ANSI barvy
GREEN="\033[32m"           # spotřeba
YELLOW="\033[38;5;214m"    # export do sítě (zlatá)
BLUE_FALLBACK="\033[38;5;33m"
BLUE_TRUECOLOR="\033[38;2;33;150;243m"
GRAY="\033[90m"            # nevyužitá kapacita
RESET="\033[0m"

if [[ "${COLORTERM:-}" == *truecolor* || "${TERM:-}" == *direct* ]]; then
    BLUE="$BLUE_TRUECOLOR"
else
    BLUE="$BLUE_FALLBACK"
fi

normalize_number() {
    printf "%s" "$1" | tr ',' '.'
}

format_kw() {
    LC_NUMERIC=C awk -v watts="$1" 'BEGIN {printf "%.2f", watts / 1000}' | tr '.' ','
}

repeat_char() {
    local count=$1
    local char=$2
    local i
    local output=""

    if (( count <= 0 )); then
        printf ""
        return
    fi

    for ((i = 0; i < count; i++)); do
        output+="$char"
    done

    printf "%s" "$output"
}

draw_bar() {
    local pv_w=$1
    local load_w=$2
    local grid_w=$3
    local covered_load uncovered_load export_load
    local covered_len uncovered_len export_len empty_len
    local covered_bar uncovered_bar export_bar empty_bar
    local pv_kw load_kw grid_kw
    local grid_color

    # Nahradit čárky tečkami a převést na číselné hodnoty
    pv_w=$(normalize_number "$pv_w")
    load_w=$(normalize_number "$load_w")
    grid_w=$(normalize_number "$grid_w")

    load_w=${load_w#-}
    pv_w=${pv_w:-0}
    load_w=${load_w:-0}
    grid_w=${grid_w:-0}

    pv_kw=$(format_kw "$pv_w")
    load_kw=$(format_kw "$load_w")
    grid_kw=$(format_kw "$grid_w")

    # Vypočítat pokrytou spotřebu (zelená), nepokrytou spotřebu (červená) a export (žlutá)
    covered_load=$(LC_NUMERIC=C awk -v pv="$pv_w" -v load="$load_w" 'BEGIN {print (pv <= load) ? pv : load}')
    uncovered_load=$(LC_NUMERIC=C awk -v pv="$pv_w" -v load="$load_w" 'BEGIN {print (load > pv) ? load - pv : 0}')
    export_load=$(LC_NUMERIC=C awk -v pv="$pv_w" -v load="$load_w" 'BEGIN {print (pv > load) ? pv - load : 0}')

    covered_len=$(LC_NUMERIC=C awk -v load="$covered_load" -v cell="$CELL_POWER" 'BEGIN {printf "%d", ((load + (cell / 2)) / cell)}')
    uncovered_len=$(LC_NUMERIC=C awk -v load="$uncovered_load" -v cell="$CELL_POWER" 'BEGIN {printf "%d", ((load + (cell / 2)) / cell)}')
    export_len=$(LC_NUMERIC=C awk -v load="$export_load" -v cell="$CELL_POWER" 'BEGIN {printf "%d", ((load + (cell / 2)) / cell)}')

    # Zajistit nezáporné délky
    covered_len=$(( covered_len < 0 ? 0 : covered_len ))
    uncovered_len=$(( uncovered_len < 0 ? 0 : uncovered_len ))
    export_len=$(( export_len < 0 ? 0 : export_len ))
    covered_len=$(( covered_len > BAR_CELLS ? BAR_CELLS : covered_len ))
    uncovered_len=$(( uncovered_len > BAR_CELLS ? BAR_CELLS : uncovered_len ))
    export_len=$(( export_len > BAR_CELLS ? BAR_CELLS : export_len ))

    if (( covered_len + uncovered_len + export_len > BAR_CELLS )); then
        export_len=$((BAR_CELLS - covered_len - uncovered_len))
        export_len=$(( export_len < 0 ? 0 : export_len ))
    fi

    empty_len=$((BAR_CELLS - covered_len - uncovered_len - export_len))
    empty_len=$(( empty_len < 0 ? 0 : empty_len ))

    covered_bar=$(repeat_char "$covered_len" "$FILLED_CHAR")
    uncovered_bar=$(repeat_char "$uncovered_len" "$FILLED_CHAR")
    export_bar=$(repeat_char "$export_len" "$FILLED_CHAR")
    empty_bar=$(repeat_char "$empty_len" "$EMPTY_CHAR")

    # barva pro grid: záporné = export žlutě, kladné = import červeně
    if (( $(LC_NUMERIC=C awk -v grid="$grid_w" 'BEGIN {print (grid < 0)}') )); then
        grid_color=$YELLOW
    else
        grid_color=$BLUE
    fi

    # výpis s obarvenou spotřebovanou částí
    printf "[%b%s%b%b%s%b%b%s%b%b%s%b] %s/%b%s%b/%b%s%b\n" \
        "$GREEN" "$covered_bar" "$RESET" \
        "$BLUE" "$uncovered_bar" "$RESET" \
        "$YELLOW" "$export_bar" "$RESET" \
        "$GRAY" "$empty_bar" "$RESET" \
        "$pv_kw" "$GREEN" "$load_kw" "$RESET" \
        "$grid_color" "$grid_kw" "$RESET"
}

echo "Monitoring FVE (Ctrl+C pro ukončení)"
echo "Formát: graf  P/L/G (kW) - ${BAR_CELLS} poli po ${CELL_POWER} W"
echo

while true; do
    response=$(curl -s "$URL")

    if [ -n "$response" ]; then
        pv=$(echo "$response" | jq -r '.site.P_PV // 0' | tr ',' '.')
        load=$(echo "$response" | jq -r '.site.P_Load // 0' | tr ',' '.')
        grid=$(echo "$response" | jq -r '.site.P_Grid // 0' | tr ',' '.')

        draw_bar "$pv" "$load" "$grid"
    else
        echo "Chyba načtení..."
    fi

    sleep $INTERVAL
done
