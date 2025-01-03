#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Le script prend exactement 1 argument : le fichier contenant les URLs"
  exit 1
fi

fichier_url=$1
num_ligne=1

# Création des répertoires nécessaires
mkdir -p ../aspirations
mkdir -p ../dumps-text
mkdir -p ../tableaux

# Début du tableau HTML
echo "<html>
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
    <table>
        <thead>
            <tr>
                <th>N° de ligne</th>
                <th>Lien des URLs</th>
                <th>Type d'encodage</th>
                <th>Nombre de mots</th>
                <th>Nombre d'occurrences</th>
                <th>Lien des aspirations</th>
                <th>Lien des dumps</th>
            </tr>
        </thead>
        <tbody>" > ../tableaux/tableau_ch.html

# Lecture et traitement des URLs
while read -r url; do
    file_path="../aspirations/chinois-$num_ligne.html"

    # Téléchargement du fichier HTML si absent
    if [ ! -f "$file_path" ]; then
        echo "Téléchargement de $url vers $file_path..."
        curl --connect-timeout 5 -s -L -o "$file_path" "$url"

        if [ $? -ne 0 ] || [ ! -s "$file_path" ]; then
            echo "Erreur : Échec du téléchargement pour $url" >&2
            echo "<html>
<head><meta charset='UTF-8'></head>
<body>Impossible de télécharger $url</body>
</html>" > "$file_path"
        fi
    fi

    # Analyse du fichier téléchargé
    reponse=$(curl --connect-timeout 5 -s -L -w "%{content_type}\t%{http_code}" -o /dev/null "$url")
    http_code=$(echo "$reponse" | cut -f2)
    content_type=$(echo "$reponse" | cut -f1)
    # encodage=$(echo "$content_type" | egrep -o "charset=\S+" | cut -d "=" -f2 | tail -n1)
    # encodage=${encodage:-"N/A"}
    encodage=$(curl -sI "$url" | grep -i "Content-Type" | sed -n 's/.*charset=\([^;]*\).*/\1/p')
	encodage=${encodage:-"N/A"}

    if [ "$http_code" != "200" ]; then
        echo "URL invalide ou introuvable : code HTTP = $http_code" >&2
        nb_mots="/"
        encodage="/"
        compte="/"
    else
        # Comptage des mots dans le fichier
        nb_mots=$(lynx -dump -nolist "$file_path" | wc -w)

        # Création du dump
        dump_path="../dumps-text/chinois-$num_ligne.txt"
        lynx -dump -nolist "$file_path" > "$dump_path"

        # Comptage des occurrences du mot
        compte=$(egrep -i -o "\b奇幻?\b" "$dump_path" | wc -l)

    fi

    # Liens pour le tableau HTML
    aspiration="<a href='../aspirations/chinois-$num_ligne.html'>aspiration</a>"
    dumplink="<a href='../dumps-text/chinois-$num_ligne.txt'>dump</a>"

    # Ajout de la ligne au tableau HTML
    echo "        <tr>
            <td>$num_ligne</td>
            <td><a href=\"$url\">$url</a></td>
            <td>$encodage</td>
            <td>$nb_mots</td>
            <td>$compte</td>
            <td>$aspiration</td>
            <td>$dumplink</td>
        </tr>" >> ../tableaux/tableau_ch.html

    # Incrémentation du numéro de ligne
    num_ligne=$((num_ligne + 1))

done < "$fichier_url"

# Fermeture du tableau HTML
echo "        </tbody>
    </table>
</body>
</html>" >> ../tableaux/tableau_ch.html

echo "Tableau généré avec succès dans ../tableaux/tableau_ch.html"

