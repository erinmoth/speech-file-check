#!/bin/bash

cd /data
rm check.txt
rm out.csv
COUNTER=1
echo "Checking files..."
echo "0" >> out.csv
for FILE in $(find -name \*.wav); do
    stats=$(sox "$FILE" -n stats 2>&1 |\
        grep "Pk lev dB\|RMS Pk dB\|RMS Tr dB\|Flat factor\|Pk count" |\
        sed 's/[^0-9.-]*//g')
    stats="${COUNTER},${stats}"
    peak=$(head -n 1 <<< "$stats")
    rmsmax=$(head -n 2 <<< "$stats" | tail -n 1)
    rmsmin=$(head -n 3 <<< "$stats" | tail -n 1)
    flatfac=$(head -n 4 <<< "$stats" |tail -n 1)
    pkcount=$(tail -n 1 <<<"$stats")
    if [[ $rmsmax > "-30" ]]
    then 
        echo "
        $FILE - check volume
        max RMS: $rmsmax
        min RMS: $rmsmin
        flats: $flatfac
        peaks: $pkcount
        " >> check.txt

    elif [[ $flatfac > "20" ]]
    then
    echo "
        $FILE - check for clipping
        max RMS: $rmsmax
        min RMS: $rmsmin
        flats: $flatfac
        peaks: $pkcount
        " >> check.txt
   
    fi; 
    printf '%s\n' $stats | tr "\n" "," >> out.csv
    echo >> out.csv
    let COUNTER++
    done
    
echo "What column do you want to plot?"
read ycolumn
echo "Name of xlabel"
read xlabel
echo "Name of ylabel"
read ylabel
echo "Name of graph"
read graphTitle
gnuplot << EOF
set terminal png size 800,800
set output '$graphTitle.png'
set datafile separator ","
set grid
set xlabel "$xlabel"
set ylabel "$ylabel"
set title "$graphTitle"
set nokey
plot "out.csv" using 1:$ycolumn 
EOF
