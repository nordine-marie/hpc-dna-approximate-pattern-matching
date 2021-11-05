#!/bin/bash

#APM original
echo "making the original apm ==============="
cd apm/apm_original
make clean
make
cd ../

#APM OpenMP
echo "making the OpenMP apm ==============="
cd apm/apm_omp
make clean
make
cd ../

#APM MPI
echo "making the MPI apm ==============="
cd apm/apm_mpi
make clean
make
cd ../

#APM OpenMP + MPI
echo "making the original OpenMP + MPI apm ==============="
cd apm/apm_omp_mpi
make clean
make
cd ../

#APM Cuda
echo "making the original CUDA apm ==============="
cd apm/apm_cuda/src
make clean
make
cd ../../