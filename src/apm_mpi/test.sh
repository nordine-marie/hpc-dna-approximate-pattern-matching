make clean
make
echo "MPI APM"
mpirun -np 2 apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTT

