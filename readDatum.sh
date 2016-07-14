#!/bin/bash

function readDatum {
        # rozsekame datum
        DEN=$(echo $1 | cut -d '.' -f1)
        MESIC=$(echo $1 | cut -d '.' -f2)
        ROK=$(echo $1 | cut -d '.' -f3 | cut -c 3,4)
        [[ $ROK == "" ]] && ROK=$(echo $1 | cut -d '.' -f3 | cut -c 1,2)

        # dodame nuly
        DEN=$(expr $DEN + 0)
        expr $DEN \< 10 >/dev/null && DEN=$(echo "0$DEN")
        MESIC=$(expr $MESIC + 0)
        expr $MESIC \< 10 >/dev/null && MESIC=$(echo "0$MESIC")

        # spojime do vstupniho formatu pro DATE
        DATE=$(echo "$MESIC${DEN}0000$ROK")

        # revedeme na UNIXTIME
        STAMP=$(date -ju $DATE +%s)
        echo "$STAMP"
}

