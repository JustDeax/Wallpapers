#!/usr/bin/env bash

WALLPAPER_DIR="."
README_FILE="README.md"
EXTENSIONS="png|jpg|jpeg|webp|gif"

if [ ! -d "$WALLPAPER_DIR" ]; then
  echo "Error: Directory '$WALLPAPER_DIR' does not exist."
  exit 1
fi

if [ ! -f "$README_FILE" ]; then
  echo "Error: '$README_FILE' not found."
  exit 1
fi

if ! grep -q "<!-- WALLPAPERS:START -->" "$README_FILE" || ! grep -q "<!-- WALLPAPERS:END -->" "$README_FILE"; then
  echo "Error: Could not find required comment markers in $README_FILE:"
  echo "  <!-- WALLPAPERS:START -->"
  echo "  <!-- WALLPAPERS:END -->"
  exit 1
fi

TEMP_GALLERY=$(mktemp)

echo '<table>' > "$TEMP_GALLERY"

counter=0

if find --version >/dev/null 2>&1; then
  FIND_CMD=(find "$WALLPAPER_DIR" -type f -regextype posix-extended -iregex ".*\.($EXTENSIONS)")
else
  FIND_CMD=(find -E "$WALLPAPER_DIR" -type f -iregex ".*\.($EXTENSIONS)")
fi

"${FIND_CMD[@]}" | sort | while read -r file; do
  clean_path="${file#./}"
  filename=$(basename "$file")

  if [ $((counter % 2)) -eq 0 ]; then
    echo '  <tr>' >> "$TEMP_GALLERY"
  fi

  echo '    <td width="50%" align="center">' >> "$TEMP_GALLERY"
  echo "      <img src=\"$clean_path\" alt=\"$filename\" style=\"max-width:100%; height:auto;\">" >> "$TEMP_GALLERY"
  echo '    </td>' >> "$TEMP_GALLERY"

  counter=$((counter + 1))

  if [ $((counter % 2)) -eq 0 ]; then
    echo '  </tr>' >> "$TEMP_GALLERY"
  fi
done

if [ $((counter % 2)) -ne 0 ]; then
  echo '    <td width="50%"></td>' >> "$TEMP_GALLERY"
  echo '  </tr>' >> "$TEMP_GALLERY"
fi

echo '</table>' >> "$TEMP_GALLERY"

awk -v gallery="$(cat "$TEMP_GALLERY")" '
  /<!-- WALLPAPERS:START -->/ { print; print gallery; flag=1; next }
  /<!-- WALLPAPERS:END -->/ { flag=0 }
  !flag
' "$README_FILE" > "${README_FILE}.tmp" && mv "${README_FILE}.tmp" "$README_FILE"

rm "$TEMP_GALLERY"

echo "Updated $README_FILE"
