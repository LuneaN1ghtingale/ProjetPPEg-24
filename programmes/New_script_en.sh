#!/bin/bash

# Récupérez le chemin absolu du fichier txt
input_file="./urls/anglais.txt"

# Vérifiez si le fichier existe
if [ ! -f "$input_file" ]; then
  echo "Le fichier $input_file n'existe pas. Veuillez vérifier le chemin."
  exit 1
fi

# Définir le fichier de sortie
output_file="./tableaux/tableau_en.html"

# Réinitialiser le contenu du fichier HTML
echo "" > "$output_file"

# Créez les dossiers "x" et "y" pour stocker les pages HTML et TXT si ce n'est pas déjà fait
output_dir_html="aspirations"
output_dir_txt="dumps-txt"
mkdir -p "$output_dir_html"
mkdir -p "$output_dir_txt"

# Début du fichier HTML
html_output="<html>
<head>
<title>Résultats</title>
</head>
<body>
<table border='1'>
<tr>
<th>Ligne</th>
<th>URL</th>
<th>Occurrences de 'fantastic'</th>
<th>Occurrences de 'fantasy'</th>
<th>Nombre total de mots</th>
<th>Encodage</th>
</tr>"

# Initialiser un compteur d'URL
url_number=0

# Parcourez chaque URL du fichier txt
while IFS= read -r url; do
  # Incrémenter le numéro de l'URL
  url_number=$((url_number + 1))

  # Obtenez le code HTTP
  echo "Vérification de l'URL : $url"
  http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 15 "$url")
  echo "Code HTTP : $http_code"

  # Vérifiez si le code HTTP est 200
  if [ "$http_code" -ne 200 ]; then
    echo "L'URL n'est pas accessible (code HTTP: $http_code) : $url"
    html_output+="<tr>
    <th>${url_number}</th>
    <th>${url}</th>
    <th>/</th>
    <th>/</th>
    <th>/</th>
    </tr>"
    continue
  fi

  # Téléchargez le contenu de l'URL
  echo "Téléchargement du contenu pour l'URL : $url"
  content=$(curl -s --max-time 15 "$url")

  # Vérifiez si le contenu est vide
  if [ -z "$content" ]; then
    echo "Le contenu est vide pour l'URL : $url"
    html_output+="<tr>
    <th>${url_number}</th>
    <th>${url}</th>
    <th>/</th>
    <th>/</th>
    <th>/</th>
    </tr>"
    continue
  fi


  # Enregistrez la page HTML dans le dossier "x"
  page_file_html="${output_dir_html}/english_${url_number}.html"
  echo "$content" > "$page_file_html"
  echo "Page HTML enregistrée : $page_file_html"

  # Enregistrez la page en texte brut dans le dossier "y"
  page_file_txt="${output_dir_txt}/english_${url_number}.txt"
  echo "$content" | grep -o '>[^	<]*<' | sed 's/[<>]//g' > "$page_file_txt"
  echo "Page texte enregistrée : $page_file_txt"

  # Comptez le nombre d'occurrences du mot "fantastic"
  count_fantastic=$(echo "$content" | grep -o -i "fantastic" | wc -l)
  echo "Nombre d'occurrences de 'fantastic' : $count"

    # Comptez le nombre d'occurrences du mot "fantay"
  count_fantasy=$(echo "$content" | grep -o -i "fantasy" | wc -l)
  echo "Nombre d'occurrences de 'fantasy' : $count"

  # Comptez le nombre total de mots dans le contenu
  total_words=$(echo "$content" | wc -w)
  echo "Nombre total de mots : $total_words"

  # Détecter l'encodage de la page
encoding=$(curl -s -I "$url" | grep -i "content-type" | grep -o -E "charset=[^;]+" | cut -d'=' -f2)
encoding=${encoding:-"Inconnu"}
echo "Encodage détecté : $encoding"


  # Ajoutez les résultats au tableau HTML avec un lien cliquable pour l'URL
  html_output+="<tr>
  <th>${url_number}</th>
  <th><a href='${url}' target='_blank'>${url}</a></th>
  <th>${count_fantastic}</th>
  <th>${count_fantasy}</th>
  <th>${total_words}</th>
  <th>${encoding}</th>
  </tr>"

done < "$input_file"

# Fin du fichier HTML
html_output+="</table></body></html>"

# Enregistrez les résultats dans un fichier HTML
echo "$html_output" > "$output_file"

echo "Les résultats ont été enregistrés dans le fichier $output_file, les pages HTML dans le dossier $output_dir_html, et les pages TXT dans le dossier $output_dir_txt"
