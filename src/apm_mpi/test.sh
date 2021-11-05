make clean
make
echo "___________________MPI_APM_Below__________________"
mpirun -np 2 ./apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA
echo "___________________Original_APM_Below______________________"
../apm_original/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

