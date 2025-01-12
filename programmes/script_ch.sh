#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Le script prend exactement 1 argument : le fichier contenant les URLs"
  exit 1
fi

fichier_url=$1
num_ligne=1

mkdir -p ../aspirations
mkdir -p ../dumps-text
mkdir -p ../contexte
mkdir -p ../concordances
mkdir -p ../tableaux

cat <<EOF > ../tableaux/tableau_ch.html
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
        .mot-cible {
            font-weight: bold;
            color: red;
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
                <th>Aspiration</th>
                <th>Dump</th>
                <th>Contexte</th>
                <th>Concordances</th>
            </tr>
        </thead>
        <tbody>
EOF

while read -r url; do
    http_code=$(curl -sI -L "$url" -o /dev/null -w "%{http_code}")

    if [[ "$http_code" != 2* && "$http_code" != 3* ]]; then
        echo "URL invalide ou introuvable : code HTTP = $http_code" >&2
        echo "  <tr>
                <td>$num_ligne</td>
                <td><a href=\"$url\">$url</a></td>
                <td>/</td>
                <td>/</td>
                <td>/</td>
                <td>/</td>
                <td>/</td>
                <td>/</td>
                <td>/</td>
              </tr>" >> ../tableaux/tableau_ch.html
    else
        file_path="../aspirations/chinois-$num_ligne.html"
        if [ ! -f "$file_path" ]; then
            echo "Téléchargement de $url vers $file_path..."
            curl --connect-timeout 5 -s -L -o "$file_path" "$url"
            # Si échec du téléchargement, on crée une page HTML d’erreur
            if [ $? -ne 0 ] || [ ! -s "$file_path" ]; then
                echo "Erreur : Échec du téléchargement pour $url" >&2
                cat <<EOD > "$file_path"
<html>
<head><meta charset='UTF-8'></head>
<body>Impossible de télécharger $url</body>
</html>
EOD
            fi
        fi

        # Détection de l'encodage
        content_type=$(curl -sI -L "$url" | grep -i "Content-Type")
        if [[ "$content_type" =~ charset=([a-zA-Z0-9-]+) ]]; then
            encodage="${BASH_REMATCH[1]}"
        else
            html_content=$(curl -sL "$url")
            encodage=$(echo "$html_content" \
                | sed -nE 's/.*<meta[^>]*charset="?([^"]*)"?[^>]*>.*/\1/ip' \
                | head -n1)
            if [ -z "$encodage" ]; then
                encodage=$(echo "$html_content" \
                    | sed -nE 's/.*<meta[^>]*http-equiv="?Content-Type"?[^>]*content="?[^"]*charset=([^";]+)"?[^>]*>.*/\1/ip' \
                    | head -n1)
            fi
            encodage=${encodage:-"N/A"}
        fi

        # Dump text
        dump_path="../dumps-text/chinois-$num_ligne.txt"
        lynx -dump -nolist "$file_path" > "$dump_path"

        # Nombre total de mots
        nb_mots=$(wc -w < "$dump_path")

        # Compte des occurrences
        compte=$(egrep -i -o "奇幻?" "$file_path" | wc -l)

        # Contexte: nettoyage
clean_sed_exprs=(
  -e '/IFRAME:/d'
  -e '/(BUTTON)/d'
  -e '/\[.*\]/d'
  -e '/http/d'
  -e 's/^[[:space:]]*//'
  -e '/^(\*|\+) ([^ ]+ ){0,2}[^ ]*$/d'
  -e 's/<[^>]*>//g'
  -e 's/\r//g'
  -e '/^[[:space:]]*$/d'
  -e 's/\[[0-9]+\]//g'
  -e '/^References/Id'
  -e '/^mailto:/Id'
  -e '/^URL:/Id'
)

context_path="../contexte/chinois-$num_ligne.txt"
sed -E "${clean_sed_exprs[@]}" "$dump_path" > "$context_path"


        # Concordances
# ...
concordance_path="../concordances/chinois-$num_ligne.html"
{
  echo "<html>"
  echo "<head>"
  echo "<meta charset='UTF-8'>"
  echo "<style>"
  echo "table { border-collapse: collapse; width: 100%; }"
  echo "th, td { border: 1px solid #aaa; padding: 8px; }"
  echo "th { background-color: #f2f2f2; }"
  echo ".mot-cible { font-weight: bold; }"
  echo "</style>"
  echo "</head>"
  echo "<body>"
  echo "<table>"
  echo "<tr>"
  echo "  <th>Contexte gauche</th>"
  echo "  <th>Mot</th>"
  echo "  <th>Contexte droit</th>"
  echo "</tr>"

  while IFS= read -r line; do
    # On remplace ! et ? par un point pour découper naïvement en phrases
    line=$(echo "$line" | tr '?!' '.')
    IFS='.' read -ra phrases <<< "$line"

    for phrase in "${phrases[@]}"; do
      # Vérifie si la phrase contient le mot
      if echo "$phrase" | grep -qi "奇幻\?"; then

        # Extraction gauche / mot / droite
        left=$(echo "$phrase"   | sed -E "s/(.*)(奇幻\?*)(.*)/\1/; t; d")
        center=$(echo "$phrase" | sed -E "s/(.*)(奇幻\?*)(.*)/\2/; t; d")
        right=$(echo "$phrase"  | sed -E "s/(.*)(奇幻\?*)(.*)/\3/; t; d")

        # Si center n’est pas vide, c’est qu’on a trouvé le mot
        if [[ -n "$center" ]]; then
          # Échappement minimal des chevrons
          left_esc=$(echo "$left"   | sed 's/</\&lt;/g; s/>/\&gt;/g')
          center_esc=$(echo "$center" | sed 's/</\&lt;/g; s/>/\&gt;/g')
          right_esc=$(echo "$right"  | sed 's/</\&lt;/g; s/>/\&gt;/g')

          echo "<tr>"
          echo "  <td>$left_esc</td>"
          echo "  <td class='mot-cible'>$center_esc</td>"
          echo "  <td>$right_esc</td>"
          echo "</tr>"
        fi
      fi
    done
  done < "$context_path"

  echo "</table>"
  echo "</body></html>"
} > "$concordance_path"
# ...



        # Liens pour la table HTML
        aspiration_link="<a href='../aspirations/chinois-$num_ligne.html'>aspiration</a>"
        dump_link="<a href='../dumps-text/chinois-$num_ligne.txt'>dump</a>"
        contexte_link="<a href='../contexte/chinois-$num_ligne.txt'>contexte</a>"
        concordance_link="<a href='../concordances/chinois-$num_ligne.html'>concordances</a>"

        echo "  <tr>
                <td>$num_ligne</td>
                <td><a href=\"$url\">$url</a></td>
                <td>$encodage</td>
                <td>$nb_mots</td>
                <td>$compte</td>
                <td>$aspiration_link</td>
                <td>$dump_link</td>
                <td>$contexte_link</td>
                <td>$concordance_link</td>
              </tr>" >> ../tableaux/tableau_ch.html
    fi

    num_ligne=$((num_ligne + 1))
done < "$fichier_url"

cat <<EOF >> ./tableaux/tableau_ch.html
        </tbody>
    </table>
</body>
</html>
EOF

echo "Tableau généré avec succès dans ../tableaux/tableau_ch.html"

