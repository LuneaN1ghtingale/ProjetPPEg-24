#!/usr/bin/env bash

if [ $# -ne 1 ]
then
  echo "Le script prend exactement 1 argument"
  exit 1
fi

fichier_url=$1
num_ligne=1
mot="fantastique"

cat <<EOF > ./tableaux/tableau_fr.html
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

while read -r url
do
	reponse=$(curl --connect-timeout 5 -s -L -w  "%{content_type}\t%{http_code}" -o ./aspirations/français-$num_ligne.html $url)
	echo $url
        http_code=$(echo "$reponse" | cut -f2)
        content_type=$(echo "$reponse" | cut -f1)
 	encodage=$(echo "$content_type" | egrep -o "charset=\S+" | cut -d "=" -f2 | tail -n1)
        encodage=${encodage:-"N/A"}
 
  
 	if [ $http_code != "200" ] ;
        then
        echo "URL invalide ou introuvable : code http = $http_code" >&2
        nb_mots="/"
        encodage="/"
        content_type="/"
        fi


	nb_mots=$(lynx "$url" -dump -nolist | wc -w)

	dump=$(lynx  -dump -nolist ./aspirations/français-$num_ligne.html > ./dumps-text/français-$num_ligne.txt)
	
	compte=$(egrep -i -o "\bfantastique(s)?\b" ./dumps-text/français-$num_ligne.txt | wc -l)

	contexte=$(egrep -i -C 2 "\bfantastique(s)?\b" ./dumps-text/français-$num_ligne.txt | sed 's/^--$/---------------/' > ./contexte/français-$num_ligne.txt)

# ...
concordance_path="./concordances/français-$num_ligne.html"
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
      # Vérifie si la
      if echo "$phrase" | egrep -qi "\bfantastique(s)?\b"; then

        # Extraction gauche / mot / droite
	left=$(echo "$phrase"   | sed -E "s/(.*)(fantastique*)(.*)/\1/; t; d")
        center=$(echo "$phrase" | sed -E "s/(.*)(fantastique*)(.*)/\2/; t; d")
        right=$(echo "$phrase"  | sed -E "s/(.*)(fantastique*)(.*)/\3/; t; d")

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
  done < ./contexte/français-$num_ligne.txt

  echo "</table>"
  echo "</body></html>"
} > "$concordance_path"
# ...
	
	# Liens pour le tableau
	aspiration_link=$(echo "<a href='../aspirations/français-$num_ligne.html'>aspiration</a>")
	dump_link=$(echo "<a href='../dumps-text/français-$num_ligne.txt'>dump</a>")
	contexte_link=$(echo "<a href='../contexte/français-$num_ligne.txt'>contexte</a>")
	concordance_link=$(echo "<a href='../concordances/français-$num_ligne.html'>concordances</a>")

	echo -e "
		<tr>
		<td>$num_ligne</td>
		<td><a class=\"has-text-primary\" href=\"$url\">$url</a></td>
		<td>$encodage</td>
		<td>$nb_mots</td>
		<td>$compte</td>
		<td>$aspiration_link</td>
		<td>$dump_link</td>
		<td>$contexte_link</td>
		<td>$concordance_link</td>
		</tr>" >> ./tableaux/tableau_fr.html
	num_ligne=$(expr $num_ligne + 1)

done < $fichier_url

cat <<EOF >> ./tableaux/tableau_fr.html
        </tbody>
    </table>
</body>
</html>
EOF

echo "Tableau généré avec succès dans ../tableaux/tableau_fr.html"

