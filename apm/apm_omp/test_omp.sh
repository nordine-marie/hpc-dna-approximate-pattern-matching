#!/bin/bash

script=$1
distance=$2
dna=$3

#patterns :
small="AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA"
medium="AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA"
large="AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA"
five_medium="'AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAG AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAT AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAGG AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAAAGTTTTTTTTTTTTTTTTTTGGAAAAAAAATT'"
patterns=($small $medium $large);

echo "OMP test" > out

for i in {1..100}; do 

    export OMP_NUM_THREADS=1
    echo "OMP_NUM_THREADS = $i =========================" >> out

    for pattern in ${patterns[*]}; do
        echo Pattern : $pattern
        $script $distance $dna $pattern | grep "APM done in" | awk '{ print $4 }' >> out
    done


done
