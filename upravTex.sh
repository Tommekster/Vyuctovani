#!/bin/bash

# nastaveni
SOUBOR="/Users/zikmundt/Documents/Prace/Xcode C/Salut/Salut_vyuctovani/Salut_vyuctovani.tex"

# nacteme radky
Radky="$(nl -b a "$SOUBOR")"

# najdeme jednotlive pasaze
b_nastav=$(echo "$Radky" | grep "BEGIN:NASTAVENI" | cut -f1)
e_nastav=$(echo "$Radky" | grep "END:NASTAVENI" | cut -f1)
b_mereni=$(echo "$Radky" | grep "BEGIN:MERENE_SLUZBY" | cut -f1)
e_mereni=$(echo "$Radky" | grep "END:MERENE_SLUZBY" | cut -f1)
b_rekapi=$(echo "$Radky" | grep "BEGIN:REKAPITULACE" | cut -f1)
e_rekapi=$(echo "$Radky" | grep "END:REKAPITULACE" | cut -f1)
b_vytape=$(echo "$Radky" | grep "BEGIN:VYTAPENI" | cut -f1)
e_vytape=$(echo "$Radky" | grep "END:VYTAPENI" | cut -f1)
konec=$(echo "$Radky" | tail -1 | cut -f1)

# soubor rozdelime do jednotlivych casti obklopujici pasaze
castA=$(head -n $b_nastav "$SOUBOR")
castB=$(head -n $b_mereni "$SOUBOR" | tail -$[$b_mereni - $e_nastav + 1])
castC=$(head -n $b_rekapi "$SOUBOR" | tail -$[$b_rekapi - $e_mereni + 1])
castD=$(head -n $b_vytape "$SOUBOR" | tail -$[$b_vytape - $e_rekapi + 1])
castE=$(tail -$[$konec - $e_vytape + 1] "$SOUBOR")

# slep to s novym obsahem
cp -r "$SOUBOR" "$SOUBOR.bak"	# udelame nejprv zalohu
(
echo "$castA"
echo "$1"
echo "$castB"
echo "$2"
echo "$castC"
echo "$3"
echo "$castD"
echo "$4"
echo "$castE"
) > "$SOUBOR"

# ZJEV HRUZU
#echo Cast A =========================================================================
#echo "$castA"
#echo 
#echo Cast B =========================================================================
#echo "$castB"
#echo 
#echo Cast C =========================================================================
#echo "$castC"
#echo 
#echo Cast D =========================================================================
#echo "$castD"
#echo 
#echo Cast E =========================================================================
#echo "$castE"
echo 
