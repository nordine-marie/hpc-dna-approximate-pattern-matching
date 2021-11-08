#!/bin/bash

distance=$1
dna=$2
char="A"
pattern=""
for i in {1..1000}; do 
    pattern="$pattern$char"
    ../../apm_original/apm $distance $dna $pattern | grep "APM done in" | awk '{ printf $4 }' >> out_cuda
    printf ";" >> out_cuda
    ./apm $distance $dna $pattern | grep "APM done in" | awk '{ printf $4 }' >> out_cuda
    printf "\n" >> out_cuda
done
