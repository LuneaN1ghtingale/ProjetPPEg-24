#!/bin/bash

# Vérifier si le fichier des URLs est fourni en argument
if [ -z "$1" ]; then
    echo "Erreur : Veuillez fournir un fichier d'URL en argument."
    exit 1
fi

# Vérifier que le fichier existe
if [ ! -f "$1" ]; then
    echo "Erreur : Le fichier '$1' n'existe pas."
    exit 1
fi

valid_url=()
invalid_url=()
num=1

# Changement de sortie en HTML
output_file="../tableaux/tableau_ch.html"
mkdir -p "../tableaux"

# En-tête HTML
echo "<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <title>Tableau des URLs</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            border: 1px solid black;
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <h1>Tableau des données récupérées</h1>
    <table>
        <thead>
            <tr>
                <th>Numéro</th>
                <th>URL</th>
                <th>Code HTTP</th>
                <th>Encodage</th>
                <th>Nombre de mots</th>
            </tr>
        </thead>
        <tbody>" > "$output_file"

# Lire le fichier ligne par ligne
while IFS= read -r line; do
    line=$(echo "$line" | xargs)  # Supprime les espaces en début et fin de ligne

    # Vérifier si l'URL commence par http ou https
    if [[ "$line" =~ ^https?:// ]]; then
        valid_url+=("$line")
    else
        invalid_url+=("$line")
    fi
done < "$1"

# Traiter les URLs valides
for url in "${valid_url[@]}"; do
    http_code=$(curl -o /dev/null -s -w "%{http_code}" "$url")
    encoding=$(curl -sI "$url" | grep -i "Content-Type" | grep -o "charset=[^;]*" | cut -d= -f2)
    word_count=$(curl -s "$url" | wc -w)

    # Vérifier si le code HTTP est une erreur (4xx ou 5xx)
    if [[ "$http_code" =~ ^[45][0-9]{2}$ ]]; then
        echo "HTTP erreur : $http_code pour $url. Vous pouvez le corriger ou réessayer plus tard."
    else
        # Ajouter une ligne au tableau HTML
        echo "            <tr>
                <td>${num}</td>
                <td><a href=\"$url\">$url</a></td>
                <td>${http_code}</td>
                <td>${encoding:-N/A}</td>
                <td>${word_count}</td>
            </tr>" >> "$output_file"
        ((num++))
    fi
done

# Fermer le tableau HTML
echo "        </tbody>
    </table>
</body>
</html>" >> "$output_file"

# Afficher les URLs invalides
if [ ${#invalid_url[@]} -gt 0 ]; then
    echo -e "\nURLs invalides :"
    for url in "${invalid_url[@]}"; do
        echo "Ce URL n'est pas correct : $url"
    done
fi

echo "La sortie a été enregistrée dans $output_file"

