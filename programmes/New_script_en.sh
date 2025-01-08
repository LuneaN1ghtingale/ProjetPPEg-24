#!/bin/bash

# Vérifie si le fichier txt existe
if [ ! -f "./urls/anglais.txt" ]; 
then
  echo "Le fichier anglais.txt n'existe pas ou n'as pas pu être trouvé. Veuillez le créer et ajouter une URL par ligne."
  exit 1
fi

# Définis le fichier de sortie
output_file="./tableaux/tableau_en.html"

# Réinitialise le contenu du tableau
echo "" > "$output_file"

# Début du fichier html
html_output="<html>
<head>
<title>Tableau occurence Anglais</title>
</head>

<body>
<table border='1'>
<tr>
<th>Ligne</th>
<th>URL</th>
<th>Occurrences</th>
<th>Nombre total de mots</th>
<th>Encodage</th>
</tr>"

# Compteur de ligne
line_number=0

# Parcoure chaque url du fichier txt
while IFS= read -r url; do
  # Incrémenter le numéro de ligne
  line_number=$((line_number + 1))

  # Télécharge le contenu de l'url avec les en-têtes
  response=$(curl -s -I --max-time 15 "$url")
  content=$(curl -s --max-time 15 "$url")

  # Vérifie si le téléchargement a réussi
  if [ $? -ne 0 ] || [ -z "$content" ]; then
    echo "Erreur lors de l'accès à l'URL : $url"
    html_output+= "<tr>
    <th>${line_number}</th>
    <th>${url}</th>
    </tr>"
    continue
  fi

  # Compte le nombre d'occurrences du mot "fantastic"
  count=$(echo "$content" | grep -o -i "fantastic" | wc -l)

  # Compte le nombre total de mots dans les pages html
  total_words=$(echo "$content" | wc -w)

  # Récupére l'encodage de la page à partir des en-têtes http
  encoding=$(echo "$response" | grep -i "content-type" | grep -o -E "charset=[^;]+" | cut -d'=' -f2)
  encoding=${encoding:-"Inconnu"}

  # Ajoute les résultats au tableau
  html_output+="<tr>
  <th>${line_number}</th>
  <th>${url}</th>
  <th>${count}</th>
  <th>${total_words}</th>
  <th>${encoding}</th>
  </tr>"
done < "./urls/anglais.txt"

# Fermeture des dernière balises
html_output+="</table></body></html>"

# Enregistre les résultats dans le fichier html
echo "$html_output" > "$output_file"

echo "Les résultats ont été enregistrés dans le fichier $output_file"

