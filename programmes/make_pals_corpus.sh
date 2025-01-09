#!/usr/bin/env bash

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <dossier_dumps> <dossier_contexte> <nom_base>"
  exit 1
fi

dossier_dumps="$1"
dossier_contexte="$2"
nom_base="$3"

mkdir -p ../pals

fichier_sortie_dumps="../pals/dump-text-$nom_base.txt"
fichier_sortie_contexte="../pals/contexte-text-$nom_base.txt"

> "$fichier_sortie_dumps"
> "$fichier_sortie_contexte"


convert_to_pals_format() {
  cat "$1" \
    | tr '?!' '.' \
    | sed 's/\./\.\n\n/g' \
    | tr -s '[:space:]' '\n' \
    | awk 'BEGIN{blank=0} NF {print; blank=0} !NF {if(!blank){print ""; blank=1}}'
}

# Traitement des fichiers dumps nommés "chinois-*.txt"
for dump_file in "$dossier_dumps"/chinois-*.txt; do
  if [[ -f "$dump_file" ]]; then
    convert_to_pals_format "$dump_file" >> "$fichier_sortie_dumps"
  fi
done

# Traitement des fichiers contexte nommés "chinois-*.txt"
for ctx_file in "$dossier_contexte"/chinois-*.txt; do
  if [[ -f "$ctx_file" ]]; then
    convert_to_pals_format "$ctx_file" >> "$fichier_sortie_contexte"
  fi
done

echo "Fichiers générés :"
echo "  -> $fichier_sortie_dumps"
echo "  -> $fichier_sortie_contexte"
