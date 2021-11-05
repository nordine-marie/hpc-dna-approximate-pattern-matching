#!/bin/bash

#APM original
echo "original apm ==============="
./apm/apm_original/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

#APM OpenMP
echo "OpenMP apm ==============="
./apm/apm_omp/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

#APM MPI
echo "MPI apm ==============="
mpirun -np 3 ./apm/apm_mpi/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

#APM OpenMP + MPI
echo "OpenMP + MPI apm ==============="
mpirun -np 3 ./apm/apm_omp_mpi/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

#APM Cuda
echo "CUDA apm ==============="
./apm/apm_cuda/src/apm 5 ./dna/chr1_KI270763v1_alt.fa AGTTTTTTTTTTTTTTTTTTGGAAAAAAAAAA

