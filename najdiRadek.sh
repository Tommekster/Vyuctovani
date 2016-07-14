#!/bin/bash

# funkce na zpracovani datumu
function readDatum {
	DAT=$(echo $1 | cut -d '.' -f1,2)
        ROK=$(echo $1 | cut -d '.' -f3 | cut -c 3,4)
        [[ $ROK == "" ]] && ROK=$(echo $1 | cut -d '.' -f3 | cut -c 1,2)

	STAMP=$(date -ju -f %d.%m.%y.%H.%M.%S $DAT.$ROK.0.0.0 +%s)
	echo "$STAMP"
}

function uDatum {
	date -ju -f %s $(readDatum "$1") +%d.%m.%Y
}

function abs {
	VALUE=$1
	expr $VALUE \< 0 >/dev/null && VALUE=$(python -c "print(($VALUE)*(-1))")
	echo $VALUE
}

function nejblizsi {
	# vstupni promenne
	SOUBOR=$1
	ourDATE=$2
	minLINE=1
	minVAL=1234567890

	## informovanost
	lins=$(echo $(nl "$SOUBOR" | tail -1 | cut -f1))
	echo -ne "\r                                        " >/dev/stderr

	while IFS= read -r radek; do
		# udaje o zaznamu
		LINE=$(echo $(echo "$radek" | cut -f1))
		DATE=$(readDatum "$(echo "$radek" | cut -f2)")
		#echo $LINE >/dev/stderr
		## informovanost
		echo -ne "\r$SOUBOR\t$LINE/$lins                    " >/dev/stderr

		ROZDIL=$(abs $(expr $ourDATE - $DATE))

		expr $ROZDIL \< $minVAL >/dev/null && minLINE=$LINE && minVAL=$ROZDIL && export minLINE=$LINE
	done <<< "$(nl "$SOUBOR")"

	echo -ne "\n                                   " >/dev/stderr
	echo $minLINE
}

function nastaveniBYTU {
	case $1 in
	1)
		echo "$BYT1"
		;;
	2)
		echo "$BYT2"
		;;
	3)
		echo "$BYT3"
		;;
	4)
		echo "$BYT4"
		;;
	*)
		echo ""
		;;
	esac
}

function spocitejTopeni {
	# vstupni promenne
	FROMLINE=$1
	TOLINE=$2
	KALORM=$3

	# inicializace vystupnich promennych
	VYSTUP=""
	SPOTREBA=0
	RADKU=0

	## informovanost
	lins=$[$TOLINE - $FROMLINE]

	# inicializace pocatecnich hodnot z prvniho radku
	zaznam=$(head -n $FROMLINE "$TOFILE" | tail -1)
	OD=$(echo "$zaznam" | cut -f1)
	PLYN1=$(echo "$zaznam" | cut -f2)
	mTM1=$(echo "$zaznam" | cut -f$[$KALORM + 2])
	oTM11=$(echo "$zaznam" | cut -f3)
	oTM21=$(echo "$zaznam" | cut -f4)
	oTM31=$(echo "$zaznam" | cut -f5)
	oTM41=$(echo "$zaznam" | cut -f6)

	# postupne nacitani spotreby
	while IFS= read -r zaznam; do
		# inicializace koncovich hodnot
		DO=$(echo "$zaznam" | cut -f1)
		PLYN2=$(echo "$zaznam" | cut -f2)
		mTM2=$(echo "$zaznam" | cut -f$[$KALORM + 2])
		oTM12=$(echo "$zaznam" | cut -f3)
		oTM22=$(echo "$zaznam" | cut -f4)
		oTM32=$(echo "$zaznam" | cut -f5)
		oTM42=$(echo "$zaznam" | cut -f6)

		# vypocet spotreby plynu a kalorimetrů
		PLYNS=$[$PLYN2 - $PLYN1]
		mTMS=$[$mTM2 - $mTM1]
		oTM1S=$[$oTM12 - $oTM11]
		oTM2S=$[$oTM22 - $oTM21]
		oTM3S=$[$oTM32 - $oTM31]
		oTM4S=$[$oTM42 - $oTM41]
		CELKS=$[$oTM1S + $oTM2S + $oTM3S + $oTM4S]

		# urceni podilu
		if [[ "$CELKS" == "0" ]];then
			mPLYS="0.0"
			pdilS="0.0 %"
		else
			mPLYS=$(python -c "print(round($PLYNS*$mTMS*1.0/$CELKS,1))")
			pdilS=$(python -c "print(round($mTMS*1.0/$CELKS,3)*100)")\ %
		fi
		SPOTREBA=$(python -c "print($SPOTREBA+$mPLYS)")

		# zapis do vystupu
		if [[ "$VYSTUP" == "" ]]; then
			VYSTUP=$(echo -ne "$OD\t$DO\t$mTM1\t$mTM2\t$mTMS\t$CELKS\t$pdilS\t$mPLYS\t$PLYNS")
		else
			VYSTUP=$(echo -ne "$VYSTUP\n\r$OD\t$DO\t$mTM1\t$mTM2\t$mTMS\t$CELKS\t$pdilS\t$mPLYS\t$PLYNS")
		fi
		RADKU=$[$RADKU + 1]

		# posun hodnot
		OD=$DO
		PLYN1=$PLYN2
		mTM1=$mTM2
		oTM11=$oTM12
		oTM21=$oTM22
		oTM31=$oTM32
		oTM41=$oTM42

		## informovanost
		echo -ne "\rRozpočet vytápění\t$RADKU/$lins                    " >/dev/stderr

	done <<< "$(head -n $TOLINE "$TOFILE" | tail -$[$TOLINE - $FROMLINE])"

	## informovanost
	echo -ne "\n                                        " >/dev/stderr

	# vystup
	echo -e "$VYSTUP\n\r$RADKU\t$SPOTREBA"
}

function sectiZalohy {
	# vstupni parametry
	[[ "$1" != "" ]] && SMLOUVA=$1 && [[ "$2" != "" ]] && POHFIL=$2

	# Vyscitame zalohy
	zalohy=0
	while IFS= read -r radek; do
		[[ "$radek" == "" ]] && radek=0
		zalohy=$(python -c "print($zalohy+$radek)")
	done <<< "$(cat "$POHFIL" | grep "$SMLOUVA	" | cut -f6 | sed s/[^0-9\-]*//g)"

	echo $(python -c "print(\"{0:.2f}\".format(round($zalohy,2)))")
}

function upravTex {

# nacteme radky
Radky="$(nl -b a "$TEXFIL")"

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
castA=$(head -n $b_nastav "$TEXFIL")
castB=$(head -n $b_mereni "$TEXFIL" | tail -$[$b_mereni - $e_nastav + 1])
castD=$(head -n $b_vytape "$TEXFIL" | tail -$[$b_vytape - $e_mereni + 1])
castC=$(head -n $b_rekapi "$TEXFIL" | tail -$[$b_rekapi - $e_vytape + 1])
#castC=$(head -n $b_rekapi "$TEXFIL" | tail -$[$b_rekapi - $e_mereni + 1])
#castD=$(head -n $b_vytape "$TEXFIL" | tail -$[$b_vytape - $e_rekapi + 1])
#castE=$(tail -$[$konec - $e_vytape + 1] "$TEXFIL")
castE=$(tail -$[$konec - $e_rekapi + 1] "$TEXFIL")

# slep to s novym obsahem
cp -r "$TEXFIL" "${TEXFIL}.bak"	# udelame nejprv zalohu
(
echo "$castA"
echo "$1"
echo "$castB"
echo "$2"
echo "$castD"
echo "$4"
echo "$castC"
echo "$3"
#echo "$castC"
#echo "$3"
#echo "$castD"
#echo "$4"
echo "$castE"
) > "$TEXFIL"

}

# import nastaveni
source config

# zeptame se na cenik 
fname=""; while [ "$fname" == "" ]; do echo "Vyber smlouvu: ";select fname in $(ls smlouvy/); do echo Byl vybrán $fname \($REPLY\); break; done; done; 
source "smlouvy/$fname"

# ziskame zakladni informace
echo -n "Zadej cislo bytu (1-4) [$S_BYT]: "
read BYT; [[ "$BYT" == "" ]] && BYT=$S_BYT
echo -n "Zadej datum od (dd.mm.rrrr) [$S_OD]: "
read DATOD; [[ "$DATOD" == "" ]] && DATOD=$S_OD
DATUMOD=$(readDatum $DATOD)
echo -n "Zadej datum do (dd.mm.rrrr) [$S_DO]: "
read DATDO; [[ "$DATDO" == "" ]] && DATDO=$S_DO
DATUMDO=$(readDatum $DATDO)
echo -n "Zadej cislo smlouvy [$S_CISLO]: "
read SMLOUVA; [[ "$SMLOUVA" == "" ]] && SMLOUVA=$S_CISLO
echo -n "Zadej jmeno [$S_JMENO]: "
read JMENO; [[ "$JMENO" == "" ]] && JMENO=$S_JMENO

# zeptame se na cenik 
fname=""; while [ "$fname" == "" ]; do echo "Vyber cenik: ";select fname in $(ls ceniky/); do echo Byl vybrán $fname \($REPLY\); break; done; done; 
cenik=$(echo $fname)
source "ceniky/$cenik"

## udelame nejake zobrazeni aktivity
echo -e "\r\n\n" >/dev/stderr

# nastaveni bytu
echo -ne "\rnacitani nastaveni                    " >/dev/stderr
SETS=$(nastaveniBYTU $BYT)
ELTR=$(echo "$SETS" | cut -d ',' -f1)
VOMR=$(echo "$SETS" | cut -d ',' -f2)
KALM=$(echo "$SETS" | cut -d ',' -f3)


# najdeme nejblizsi zaznam od
echo -ne "\nHledani pocatecniho zaznamu: \n" >/dev/stderr
elLINE1=$(nejblizsi "$ELFILE" $DATUMOD)
voLINE1=$(nejblizsi "$VOFILE" $DATUMOD)
toLINE1=$(nejblizsi "$TOFILE" $DATUMOD)

# najdeme nejblizsi zaznam do
echo -ne "\nHledani koncoveho zaznamu: \n" >/dev/stderr
elLINE2=$(nejblizsi "$ELFILE" $DATUMDO)
voLINE2=$(nejblizsi "$VOFILE" $DATUMDO)
toLINE2=$(nejblizsi "$TOFILE" $DATUMDO)

# nacteni udaju
VYTOP=$(spocitejTopeni $toLINE1 $toLINE2 $KALM)
VYTOR=$(echo "$VYTOP" | tail -1)
ELVT1=$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f$[2 * $ELTR])
ELNT1=$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f$[2 * $ELTR + 1])
VODA1=$(head -n $voLINE1 "$VOFILE" | tail -1 | cut -f$[$VOMR + 2])
ELVT2=$(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f$[2 * $ELTR])
ELNT2=$(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f$[2 * $ELTR + 1])
VODA2=$(head -n $voLINE2 "$VOFILE" | tail -1 | cut -f$[$VOMR + 2])
ELVTS=$(python -c "print($ELVT2-$ELVT1)")
ELNTS=$(python -c "print($ELNT2-$ELNT1)")
ELVNS=$(python -c "print($ELVTS+$ELNTS)")
VODAS=$(python -c "print($VODA2-$VODA1)")
TEPLO=$(echo "$VYTOR" | cut -f2)
DATS=$(python -c "print(($DATUMDO-$DATUMOD)/86400)")
MESIS=$(python -c "print(round($DATS/30.41667,3))")
DATUM_OD=$(date -ju -f %s $DATUMOD +%d.%m.%Y)
DATUM_DO=$(date -ju -f %s $DATUMDO +%d.%m.%Y)

# vypocet nakladu podle udaju z ceniku
function vyrobCenu {
	echo $(python -c "print(\"{0:.2f}\".format(round($1,2)))")
}
N_VODAk=$(vyrobCenu "$VODAS*${SVkom[0]}")
N_VODAsp=$(vyrobCenu "$DATS*${SVSP[0]}")
N_ELVT=$(vyrobCenu "$ELVTS*${ELVT[0]}")
N_ELNT=$(vyrobCenu "$ELNTS*${ELNT[0]}")
N_ELVNT=$(vyrobCenu "$ELVNS*${ELVNT[0]}")
N_ELSP=$(vyrobCenu "$MESIS*${ELSP[0]}")
N_PLkom=$(vyrobCenu "$TEPLO*${PLkom[0]}")
N_PLSP=$(vyrobCenu "$MESIS*${PLSP[0]}")
if [ "$S_ELEKT" == "1" ]; then	# jestli je zajistena dodavka elektriny
	N_CELK=$(vyrobCenu "$N_VODAk+$N_VODAsp+$N_ELVT+$N_ELNT+$N_ELVNT+$N_ELSP+$N_PLkom+$N_PLSP")
else	# nebo si ji najemce zajisti sam
	N_CELK=$(vyrobCenu "$N_VODAk+$N_VODAsp+$N_PLkom+$N_PLSP")
fi

# vypocet vyuctovani - odecist od zaloh, vyhodnotit poplatek, nedoplatek
ZALOHY=$(sectiZalohy)
NEDOPLATEK=$(python -c "print($N_CELK-$ZALOHY)")
PREPLATEK=$(python -c "print($ZALOHY-$N_CELK)")
if [[ "$(echo $NEDOPLATEK | cut -c 1)" == "-" ]]; then
	POPIS_PLATEK="Přeplatek"
	HODN_PLATEK=$PREPLATEK
else
	POPIS_PLATEK="Nedoplatek"
	HODN_PLATEK=$NEDOPLATEK
fi

# Vystupni tabulka
subter=$(
echo
echo "služba			od		do		jednotka	počátek		konec		spotřeba"
echo "======================================================================================================================="
echo "Studena voda		$(head -n $voLINE1 "$VOFILE" | tail -1 | cut -f1)	$(head -n $voLINE2 "$VOFILE" | tail -1 | cut -f1)	m3		$VODA1		$VODA2		$VODAS"
echo "Studena voda stálý plat	$DATUM_OD	$DATUM_DO	den		$DATUM_OD	$DATUM_DO	$DATS"
if [ "$S_ELEKT" == "1" ]; then	# jestli je zajistena dodavka elektriny
echo "Elektřina VT		$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)	$(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)	kWh		$ELVT1		$ELVT2		$ELVTS"
echo "Elektřina NT		$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)	$(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)	kWh		$ELNT1		$ELNT2		$ELNTS"
echo "Elektřina VT+NT		$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)	$(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)	kWh		je součtem $ELVTS + $ELNTS		$ELVNS"
echo "Elektřina stálý plat	$DATUM_OD	$DATUM_DO	měsíc		$DATUM_OD	$DATUM_DO	$MESIS"
fi
echo "Vytápění komod.		$(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)       $(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)	m3		dle zvláštního rozpisu		$TEPLO"
echo "Vytápění stálý plat	$DATUM_OD	$DATUM_DO	měsíc		$DATUM_OD	$DATUM_DO	$MESIS"
echo 
echo "služba				jednotek		jednotka	náklad		Kč/jedn.	DPH"
echo "======================================================================================================================="
echo "Studena voda			$VODAS		m3		$N_VODAk Kč	${SVkom[0]}	${SVkom[1]} %"
echo "Studena voda stálý plat		$DATS		den		$N_VODAsp Kč	${SVSP[0]}	${SVSP[1]} %"
if [ "$S_ELEKT" == "1" ]; then	# jestli je zajistena dodavka elektriny
echo "Elektřina VT			$ELVTS		kWh		$N_ELVT Kč	${ELVT[0]}	${ELVT[1]} %"
echo "Elektřina NT			$ELNTS		kWh		$N_ELNT Kč	${ELNT[0]}	${ELNT[1]} %"
echo "Elektřina VT+NT			$ELVNS		kWh		$N_ELVNT Kč	${ELVNT[0]}	${ELVNT[1]} %"
echo "Elektřina stálý plat		$MESIS		měsíc		$N_ELSP Kč	${ELSP[0]}	${ELSP[1]} %"
fi
echo "Vytápění komod.			$TEPLO		m3		$N_PLkom Kč	${PLkom[0]}	${PLkom[1]} %"
echo "Vytápění stálý plat		$MESIS		měsíc		$N_PLSP Kč	${PLSP[0]}	${PLSP[1]} %"
echo 
echo "Celkové náklady		$N_CELK Kč"
echo "Započtené zálohy	$ZALOHY Kč"
echo "$POPIS_PLATEK		$HODN_PLATEK Kč"
echo 
echo "od		do		počátek	konec	spotř.	celkem	podíl	s.plnu	sp.plynu clk."
echo "======================================================================================================================="
lins=$(echo "$VYTOR" | cut -f1)
echo "$(echo "$VYTOP" | head -n $lins)"
echo 

)
echo "$subter"

function upravTisice {
	var="$1"	# castka musi byt bez des. carky
	len=${#var} 	# urci delku castky
	if [[ "$len" > "3" ]]; then
		mil=$(echo $var | cut -c "-$[$len - 3]")
		jed=$(echo $var | cut -c "$[$len - 2]-$len")
		var=$(echo $mil~$jed)
	fi
	echo $var
}
function cenaVtexu {
	del="."
	pred=$(upravTisice $(echo "$1" | cut -d $del -f1))
	zati=$(echo "$1" | cut -d $del -f2)

	echo "$pred & $zati"
}

# tabulka měřených hodot
TEXt1=$(
echo "\begin{tabular}{lcccccc}"

echo "	\hline"
echo "	\multicolumn{1}{|c|}{\bfseries služba} & \multicolumn{1}{c|}{\bfseries od} & \multicolumn{1}{|c|}{\bfseries do} & \multicolumn{1}{|c|}{\bfseries jednotka} & \multicolumn{1}{|c|}{\bfseries počátek} & \multicolumn{1}{|c|}{\bfseries konec} & \multicolumn{1}{|c|}{\bfseries spotřeba} \\\\ \\hline\\hline"

echo "Studená voda	&	$(uDatum $(head  -n $voLINE1 "$VOFILE" | tail -1 | cut -f1)) &	$(uDatum $(head -n $voLINE2 "$VOFILE" | tail -1 | cut -f1)) &	m3	&	$VODA1	&	$VODA2	&	$VODAS \\\\ \\hline"
echo "Studená voda stálý plat	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	den	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	$DATS \\\\ \hline"
if [ "$S_ELEKT" == "1" ]; then	# jestli je zajistena dodavka elektriny
echo "Elektřina VT	&	$(uDatum $(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)) &	$(uDatum $(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)) &	kWh	&	$ELVT1	&	$ELVT2	&	$ELVTS \\\\ \\hline"
echo "Elektřina NT	&	$(uDatum $(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)) &	$(uDatum $(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)) &	kWh	&	$ELNT1	&	$ELNT2	&	$ELNTS \\\\ \\hline"
echo "Elektřina VT+NT	&	$(uDatum $(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)) &	$(uDatum $(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)) &	kWh	&	\multicolumn{2}{c}{je součtem $ELVTS + $ELNTS}	&	$ELVNS \\\\ \\hline"
echo "Elektřina stálý plat	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	měsíc	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	$MESIS \\\\ \\hline"
fi
echo "Vytápění komod.	&	$(uDatum $(head -n $elLINE1 "$ELFILE" | tail -1 | cut -f1)) &	$(uDatum $(head -n $elLINE2 "$ELFILE" | tail -1 | cut -f1)) &	m3	&	\multicolumn{2}{c}{dle zvláštního rozpisu}	&	$TEPLO \\\\ \\hline"
echo "Vytápění stálý plat	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	měsíc	&	$(uDatum $DATUM_OD) &	$(uDatum $DATUM_DO) &	$MESIS \\\\ \\hline"

echo "\end{tabular}"
)

# tabulka cen a nákladů
TEXt2=$(
echo "\begin{tabular}{lccr@{,}lr@{,}lc}"

echo "	\hline"
echo "	\multicolumn{1}{|c|}{\bfseries služba} & \multicolumn{1}{c|}{\bfseries jednotek} & \multicolumn{1}{|c|}{\bfseries jednotka} & \multicolumn{2}{|c|}{\bfseries náklad} & \multicolumn{2}{|c|}{\bfseries K\v c/jedn.} & \multicolumn{1}{|c|}{\bfseries DPH} \\\\ \\hline\\hline"

echo "Studená voda		&	$VODAS	&	m3	&	$(cenaVtexu $N_VODAk) Kč &	$(cenaVtexu ${SVkom[0]}) &	${SVkom[1]} \\% \\\\ \\hline"
echo "Studená voda stálý plat	&	$DATS	&	den	&	$(cenaVtexu $N_VODAsp) Kč &	$(cenaVtexu ${SVSP[0]}) &	${SVSP[1]} \\% \\\\ \\hline"
if [ "$S_ELEKT" == "1" ]; then	# jestli je zajistena dodavka elektriny
echo "Elektřina VT		&	$ELVTS	&	kWh	&	$(cenaVtexu $N_ELVT) Kč &	$(cenaVtexu ${ELVT[0]}) &	${ELVT[1]} \\% \\\\ \\hline"
echo "Elektřina NT		&	$ELNTS	&	kWh	&	$(cenaVtexu $N_ELNT) Kč &	$(cenaVtexu ${ELNT[0]}) &	${ELNT[1]} \\% \\\\ \\hline"
echo "Elektřina VT+NT		&	$ELVNS	&	kWh	&	$(cenaVtexu $N_ELVNT) Kč &	$(cenaVtexu ${ELVNT[0]}) &	${ELVNT[1]} \\% \\\\ \\hline"
echo "Elektřina stálý plat	&	$MESIS	&	měsíc	&	$(cenaVtexu $N_ELSP) Kč &	$(cenaVtexu ${ELSP[0]}) &	${ELSP[1]} \\% \\\\ \\hline"
fi
echo "Vytápění komod.		&	$TEPLO	&	m3	&	$(cenaVtexu $N_PLkom) Kč &	$(cenaVtexu ${PLkom[0]}) &	${PLkom[1]} \\% \\\\ \\hline"
echo "Vytápění stálý plat	&	$MESIS	&	měsíc	&	$(cenaVtexu $N_PLSP) Kč &	$(cenaVtexu ${PLSP[0]}) &	${PLSP[1]} \\% \\\\ \\hline"

echo "\\\\"

echo "\multicolumn{3}{l}{Celkové náklady}	&	$(cenaVtexu $N_CELK) Kč & \multicolumn{3}{r}{} \\\\"
echo "\multicolumn{3}{l}{Započtené zálohy}	&	$(cenaVtexu $ZALOHY) Kč	& \multicolumn{3}{r}{} \\\\"
echo "\multicolumn{3}{l}{\bfseries{$POPIS_PLATEK}}	& $(cenaVtexu $HODN_PLATEK) Kč	& \multicolumn{3}{r}{} \\\\"

echo "\end{tabular}"
)

# tabulka rozuctovani tepla
TEXt3=$(
echo "\begin{tabular}{ccccccccc}"

echo "	\hline"
#echo "  \multicolumn{1}{|c|}{\bfseries od} & \multicolumn{1}{|c|}{\bfseries do} & \multicolumn{1}{|c|}{\bfseries počátek} & \multicolumn{1}{|c|}{\bfseries konec} & \multicolumn{1}{|c|}{\bfseries spotřeba} & \multicolumn{1}{|c|}{\bfseries s. celkem} & \multicolumn{1}{|c|}{\bfseries podíl} & \multicolumn{1}{|c|}{\bfseries s.plynu} & \multicolumn{1}{|c|}{\bfseries sp.plynu clk.} \\\\ \\hline\\hline"
#echo ""
echo "    \multicolumn{1}{|c|}{} & \multicolumn{1}{|c|}{ } & \multicolumn{1}{|c|}{\bfseries počáteční} & \multicolumn{1}{|c|}{\bfseries konečný} & \multicolumn{1}{|c|}{\bfseries spotřeba} & \multicolumn{1}{|c|}{\bfseries s. tepla} & \multicolumn{1}{|c|}{\bfseries podíl} & \multicolumn{1}{|c|}{\bfseries spotřeba} & \multicolumn{1}{|c|}{\bfseries s.plynu} \\\\"
echo "    \multicolumn{1}{|c|}{\bfseries od} & \multicolumn{1}{|c|}{\bfseries do} & \multicolumn{1}{|c|}{\bfseries stav} & \multicolumn{1}{|c|}{\bfseries  stav} & \multicolumn{1}{|c|}{\bfseries tepla} & \multicolumn{1}{|c|}{\bfseries v domě} & \multicolumn{1}{|c|}{\bfseries spotřeby} & \multicolumn{1}{|c|}{\bfseries plynu} & \multicolumn{1}{|c|}{\bfseries v domě} \\\\ %\cline{2-8}"
echo "    \multicolumn{1}{|c|}{ } & \multicolumn{1}{|c|}{ } & \multicolumn{1}{|c|}{[kWh]} & \multicolumn{1}{|c|}{[kWh]} & \multicolumn{1}{|c|}{[kWh]} & \multicolumn{1}{|c|}{[kWh]} & \multicolumn{1}{|c|}{\bfseries plynu} & \multicolumn{1}{|c|}{[m$^3$]} & \multicolumn{1}{|c|}{[m$^3$]} \\\\ \\hline\\hline"

lins=$(echo "$VYTOR" | cut -f1)
subter="$(echo "$VYTOP" | head -n $lins)"
subter="$(sed "s/%/\\\\%/g" <<< "$subter")"
subter="$(sed "s/	/	\\&	/g" <<< "$subter")"
sed "s/$/	\\\\\\\\ \\\\hline /" <<< "$subter"

echo "\end{tabular}"
)
echo 
echo 

nast=$(
echo "\newcommand{\smlouva}{$SMLOUVA}"
echo "\newcommand{\byt}{$BYT}"
echo "\newcommand{\sod}{$DATUM_OD}"
echo "\newcommand{\sdo}{$DATUM_DO}"
echo "\newcommand{\zalohy}{2000~Kč}"
#echo "\newcommand{\kauceCastka}{12000~Kč}"
#echo "\newcommand{\vyhotoveni}{tři}"
#echo "\newcommand{\podpis}{\podpisA}"
echo "\newcommand{\komu}{$JMENO}"
echo "\newcommand{\dne}{$(date +%d.\ %B\ %Y)}"
echo "\newcommand{\splatnost}{$(date -ju -f %s $[$(date +%s) + 2592000] +%d.\ %B\ %Y)}"
)

#echo "$TEXt1"
#echo 
#echo "$TEXt2"
#echo 
#echo "$TEXt3"

upravTex "$nast" "$TEXt1" "$TEXt2" "$TEXt3" 
