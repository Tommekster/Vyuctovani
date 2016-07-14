#!/bin/bash

# Soubory
POHFIL="pohyby.txt"

SMLOUVA="02/2014"

# Vyscitame zalohy
zalohy=0
while IFS= read -r radek; do
	[[ "$radek" == "" ]] && radek=0
	echo $radek
	zalohy=$(python -c "print $zalohy+($radek)")
done <<< "$(cat "$POHFIL" | grep "$SMLOUVA	" | cut -f6 | sed s/[^0-9\-]*//g)"

echo $(python -c "print round($zalohy,2)")
