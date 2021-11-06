#include <stdio.h>
/* MPI function signatures */
#include <mpi.h>
#include <unistd.h>

int main(int argc, char **argv){
    /* Initialization of MPI */
    MPI_Init(&argc, &argv);
    char hostname[1024];
    hostname[1023] = '\0';
    gethostname(hostname, 1023);
    printf("Hello World from host : %s !\n",hostname);
    /* Finalization of MPI */
    MPI_Finalize();
    return 0;
}