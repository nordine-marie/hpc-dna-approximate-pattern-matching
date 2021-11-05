#!/bin/bash

#APM original
cd apm/apm_original
make clean
make
cd ../

#APM OpenMP
cd apm/apm_omp
make clean
make
cd ../

#APM MPI
cd apm/apm_mpi
make clean
make
cd ../

#APM OpenMP + MPI
cd apm/apm_opm_mpi
make clean
make
cd ../

#APM Cuda
cd apm/apm_opm_mpi/src
make clean
make
cd ../../