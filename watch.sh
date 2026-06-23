#!/bin/bash

if ! command -v inotifywait &> /dev/null; then
    echo "Error: 'inotifywait' is not installed."
    echo "Please install it using: sudo apt install inotify-tools"
    exit 1
fi

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <filename>"
    exit 1
fi

FILE=$1
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found."
    exit 1
fi

MAX_LINES=400
BAR_WIDTH=40

render_bar() {
    local lines=$1
    local display_lines=$lines
    [ "$display_lines" -gt "$MAX_LINES" ] && display_lines=$MAX_LINES

    local percent=$((display_lines * 100 / MAX_LINES))
    local filled=$((percent * BAR_WIDTH / 100))
    local empty=$((BAR_WIDTH - filled))

    printf "\rProgress: ["
    printf "%${filled}s" | tr ' ' '#'
    printf "%${empty}s" | tr ' ' '-'
    printf "] %d/%d (%d%%)" "$lines" "$MAX_LINES" "$percent"
}
clear
echo "Monitoring $FILE (Press Ctrl+C to stop)..."
render_bar "$(wc -l < "$FILE")"

while inotifywait -q -e modify "$FILE" > /dev/null; do
    current_lines=$(wc -l < "$FILE")
    render_bar "$current_lines"
done