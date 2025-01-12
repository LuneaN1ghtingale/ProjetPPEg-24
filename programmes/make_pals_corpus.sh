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

# chinois en utilisant thulac
convert_to_pals_chinois() {
  python3 -c "
import sys, re, thulac
thu = thulac.thulac(seg_only=True)
for line in sys.stdin:
    line = re.sub(r'[?!]', '.', line)
    if not line.strip():
        print('')
        continue
    phrases = re.split(r'(?<=\.)', line)
    for phrase in phrases:
        phrase = phrase.strip()
        if not phrase:
            continue
        segmented = thu.cut(phrase, text=True)
        for word in segmented.split():
            print(word)
        print('')
" < "$1" | sed -E '/^#/d' | sed -E 's/[a-zA-Z]//g'
}

echo "Traitement des dumps..."
for dump_file in "$dossier_dumps"/chinois-*.txt; do
  if [[ -f "$dump_file" ]]; then
    convert_to_pals_chinois "$dump_file" >> "$fichier_sortie_dumps"
  fi
done

echo "Traitement des contextes..."
for ctx_file in "$dossier_contexte"/chinois-*.txt; do
  if [[ -f "$ctx_file" ]]; then
    convert_to_pals_chinois "$ctx_file" >> "$fichier_sortie_contexte"
  fi
done

echo "Fichiers générés :"
echo "  -> $fichier_sortie_dumps"
echo "  -> $fichier_sortie_contexte"
