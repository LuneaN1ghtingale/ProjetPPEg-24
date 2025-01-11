#!/bin/bash

# Vérifiez si le fichier contenant les URLs est fourni
if [[ -z "$1" ]]; then
  echo "Usage: $0 <fichier_urls>"
  exit 1
fi

# Fichier contenant les URLs
input_file="$1"
output_file="results_table.html"
output_dir="./tableaux"
mkdir -p "$output_dir"

# Réinitialiser le fichier HTML de sortie
echo "<html><head><title>Résultats</title></head><body><table border='1'><tr><th>Ligne</th><th>URL</th><th>Occurrences de 'fantasy'</th><th>Occurrences de 'fantastic'</th><th>Encodage</th></tr>" > "$output_file"

# Fonction pour extraire le texte propre d'une URL
extract_clean_text() {
  local url="$1"
  local output_file="$2"

  # Utiliser lynx pour extraire le texte visible et propre
  lynx -dump -nolist "$url" > "$output_file" 2>/dev/null
}

# Fonction pour détecter l'encodage via HTTP
get_encoding() {
  local url="$1"
  encoding=$(curl -s -I "$url" | grep -i "content-type" | grep -o -E "charset=[^;]+" | cut -d'=' -f2)
  echo "${encoding:-Inconnu}"
}

# Fonction pour compter les occurrences des mots cibles
count_occurrences() {
  local input_file="$1"
  local word="$2"

  grep -o -i "$word" "$input_file" | wc -l
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
    output_text_file="$output_dir/$file_name"

    echo "Extraction du texte de : $url"
    extract_clean_text "$url" "$output_text_file"
    echo "Texte enregistré dans : $output_text_file"

    # Récupérer l'encodage
    encoding=$(get_encoding "$url")

    # Compter les occurrences des mots cibles
    fantasy_count=$(count_occurrences "$output_text_file" "fantasy")
    fantastic_count=$(count_occurrences "$output_text_file" "fantastic")

    # Ajouter une ligne au tableau HTML
    echo "<tr><td>$url_number</td><td><a href='$url' target='_blank'>$url</a></td><td>$fantasy_count</td><td>$fantastic_count</td><td>$encoding</td></tr>" >> "$output_file"
  fi

done < "$input_file"

# Terminer le fichier HTML
echo "</table></body></html>" >> "$output_file"

echo "Analyse terminée. Les résultats sont dans le fichier $output_file"
