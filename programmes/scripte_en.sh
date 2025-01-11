#!/bin/bash

# Vérifiez si le fichier contenant les URLs est fourni
if [[ -z "$1" ]]; then
  echo "Usage: $0 <fichier_urls>"
  exit 1
fi

# Fichier contenant les URLs
input_file="$1"
output_dir="./dumps-txt"
mkdir -p "$output_dir"

# Fonction pour extraire le texte propre d'une URL
extract_clean_text() {
  local url="$1"
  local output_file="$2"

  # Utiliser lynx pour extraire le texte visible et propre
  lynx -dump -nolist "$url" > "$output_file" 2>/dev/null
}

# Initialiser un compteur d'URL
url_number=0

# Parcourez chaque URL dans le fichier et extrayez le texte
while IFS= read -r url; do
  if [[ -n "$url" ]]; then
    # Incrémenter le compteur
    url_number=$((url_number + 1))

    # Nom du fichier basé sur le numéro de l'URL
    file_name="english_${url_number}.txt"
    output_file="$output_dir/$file_name"

    echo "Extraction du texte de : $url"
    extract_clean_text "$url" "$output_file"
    echo "Texte enregistré dans : $output_file"
  fi

done < "$input_file"

echo "Extraction terminée. Les textes sont dans le dossier $output_dir"
