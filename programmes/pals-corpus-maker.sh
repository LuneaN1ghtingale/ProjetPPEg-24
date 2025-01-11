#!/bin/bash

# Dossier contenant les fichiers TXT
input_dir="./dumps-txt"
output_dir="./dumps-words"
mkdir -p "$output_dir"

# Fonction pour convertir un fichier TXT en format "un mot par ligne"
convert_to_words() {
  local input_file="$1"
  local output_file="$2"

  # Lire chaque ligne du fichier et séparer les mots
  while IFS= read -r line; do
    # Diviser la ligne en mots et les écrire un par un
    for word in $line; do
      echo "$word" >> "$output_file"
    done
  done < "$input_file"
}

# Parcourir tous les fichiers TXT et les convertir
for file in "$input_dir"/*.txt; do
  if [[ -f "$file" ]]; then
    output_file="$output_dir/$(basename "$file")"
    echo "Conversion de $file en $output_file"
    convert_to_words "$file" "$output_file"
  fi
done

echo "Conversion terminée. Les fichiers convertis sont dans le dossier $output_dir"
