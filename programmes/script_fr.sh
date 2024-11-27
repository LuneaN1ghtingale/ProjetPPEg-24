#!/usr/bin/env bash

if [ $# -ne 1 ]
then
  echo "Le script prend exactement 1 argument"
  exit 1
fi

fichier_url=$1
num_ligne=1

echo "<html>
<head>
<meta charset='UTF-8'>
</head>
<body>
<table>
<thead>
<tr>
<th>N° de ligne</th>
<th>URL</th>
<th>Type d'encodage</th>
<th>Nombre de mots</th>
</tr>
</thead>
<tbody>" > tableau_fr.html

while read -r line
do
	http_code=$(curl -s -I -L -w "%{http_code}" -0 /dev/null $line)
 	encoding=$(curl -s -I -L -w "%{content_type}" -0 /dev/null $line | grep -P -o "charset=\S+" | cut -d'=' -f2) 
  
 	if [ -z "$encoding" ]
 	then
	encoding="N/A"
	fi 

	nbmots=$(lynx "$line" -dump -nolist | wc -w)
	echo -e "<tr><td>$num_ligne</td><td>$line</td><td>$encoding</td><td>$nbmots</td></tr>" >> tableau_fr.html
	num_ligne=$(expr $num_ligne + 1)

done < $fichier_url

echo "</tbody>
</table>
</body>
</html>" >> tableau_fr.html
