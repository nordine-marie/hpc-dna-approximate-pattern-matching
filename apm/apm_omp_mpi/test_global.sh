#!/bin/bash

for (( i=1; i<=105; i+=5 )); do #MPI loop
    ./test_omp_mpi.sh ./apm 5 ../../dna/chr1_KI270763v1_alt.fa $i
done

echo "I'm done !"