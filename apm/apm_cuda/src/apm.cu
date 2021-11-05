/**
 * APPROXIMATE PATTERN MATCHING
 *
 * INF560 X2016
 */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/time.h>

#include <cuda.h>
#include <cuda_runtime.h>
#include <helper_cuda.h>

#define APM_DEBUG 0

char *
read_input_file(char *filename, int *size)
{
    char *buf;
    off_t fsize;
    int fd = 0;
    int n_bytes = 1;

    /* Open the text file */
    fd = open(filename, O_RDONLY);
    if (fd == -1)
    {
        fprintf(stderr, "Unable to open the text file <%s>\n", filename);
        return NULL;
    }

    /* Get the number of characters in the textfile */
    fsize = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);

    /* TODO check return of lseek */

#if APM_DEBUG
    printf("File length: %lld\n", fsize);
#endif

    /* Allocate data to copy the target text */
    buf = (char *)malloc(fsize * sizeof(char));
    if (buf == NULL)
    {
        fprintf(stderr, "Unable to allocate %ld byte(s) for main array\n", fsize);
        return NULL;
    }

    n_bytes = read(fd, buf, fsize);
    if (n_bytes != fsize)
    {
        fprintf(stderr, "Unable to copy %ld byte(s) from text file (%d byte(s) copied)\n", fsize, n_bytes);
        return NULL;
    }

#if APM_DEBUG
    printf("Number of read bytes: %d\n", n_bytes);
#endif

    *size = n_bytes;

    close(fd);

    return buf;
}

#define MIN3(a, b, c) ((a) < (b) ? ((a) < (c) ? (a) : (c)) : ((b) < (c) ? (b) : (c)))

__global__ void cuda_levenshtein(char *s1, char *s2, int len, int *column, int *gpu_column)
{
    unsigned int x, y, lastdiag, olddiag;

    int i = blockIdx.x * blockDim.x + threadIdx.x;

    for (y = 1; y <= len; y++)
    {
        column[y] = y;
    }
    for (x = 1; x <= len; x++)
    {
        column[0] = x;
        lastdiag = x - 1;
        for (y = 1; y <= len; y++)
        {
            olddiag = column[y];
            column[y] = MIN3(
                column[y] + 1,
                column[y - 1] + 1,
                lastdiag + (s1[y - 1] == s2[x - 1+i] ? 0 : 1));
            lastdiag = olddiag;
        }
    }
    printf("coucou");
    gpu_column[i] = column[len];
}

int main(int argc, char **argv)
{
    char **pattern;
    char *filename;
    int approx_factor = 0;
    int nb_patterns = 0;
    int i;
    char *buf;
    struct timeval t1, t2;
    double duration;
    int n_bytes;
    int *n_matches;

    /* Check number of arguments */
    if (argc < 4)
    {
        printf("Usage: %s approximation_factor "
               "dna_database pattern1 pattern2 ...\n",
               argv[0]);
        return 1;
    }

    /* Get the distance factor */
    approx_factor = atoi(argv[1]);

    /* Grab the filename containing the target text */
    filename = argv[2];

    /* Get the number of patterns that the user wants to search for */
    nb_patterns = argc - 3;

    /* Fill the pattern array */
    pattern = (char **)malloc(nb_patterns * sizeof(char *));
    if (pattern == NULL)
    {
        fprintf(stderr,
                "Unable to allocate array of pattern of size %d\n",
                nb_patterns);
        return 1;
    }

    /* Grab the patterns */
    for (i = 0; i < nb_patterns; i++)
    {
        int l;

        l = strlen(argv[i + 3]);
        if (l <= 0)
        {
            fprintf(stderr, "Error while parsing argument %d\n", i + 3);
            return 1;
        }

        pattern[i] = (char *)malloc((l + 1) * sizeof(char));
        if (pattern[i] == NULL)
        {
            fprintf(stderr, "Unable to allocate string of size %d\n", l);
            return 1;
        }

        strncpy(pattern[i], argv[i + 3], (l + 1));
    }

    printf("Approximate Pattern Mathing: "
           "looking for %d pattern(s) in file %s w/ distance of %d\n",
           nb_patterns, filename, approx_factor);

    buf = read_input_file(filename, &n_bytes);
    if (buf == NULL)
    {
        return 1;
    }

    /* Allocate the array of matches */
    n_matches = (int *)malloc(nb_patterns * sizeof(int));
    if (n_matches == NULL)
    {
        fprintf(stderr, "Error: unable to allocate memory for %ldB\n",
                nb_patterns * sizeof(int));
        return 1;
    }

    /*****
   * BEGIN MAIN LOOP
   ******/

    /* Timer start */
    gettimeofday(&t1, NULL);
    int blocksize = 1024;
    int *gpu_column;
    char *gpu_pattern;
    char *gpu_buf;

    for (i = 0; i < nb_patterns; i++)
    {
        int size_pattern = strlen(pattern[i]);

        int *column;

        n_matches[i] = 0;

        column = (int *)malloc((size_pattern + 1) * sizeof(int));
        if (column == NULL)
        {
            fprintf(stderr, "Error: unable to allocate memory for column (%ldB)\n",
                    (size_pattern + 1) * sizeof(int));
            return 1;
        }
        cudaMalloc(&gpu_column, (size_pattern + 1) * sizeof(int));
        cudaMalloc(&gpu_pattern, (size_pattern) * sizeof(char));
        cudaMalloc(&gpu_buf, n_bytes * sizeof(char));

        cudaMemcpy(gpu_column, column, (size_pattern + 1) * sizeof(int), cudaMemcpyHostToDevice);
        cudaMemcpy(gpu_pattern, pattern[i], (size_pattern+1) * sizeof(char), cudaMemcpyHostToDevice);
        cudaMemcpy(gpu_buf, buf, (n_bytes * n_bytes) * sizeof(char), cudaMemcpyHostToDevice);

        dim3 dimBlock(blocksize);
        dim3 dimGrid(ceil((size_pattern + 1) * sizeof(char) / (int)blocksize));

        cuda_levenshtein<<<dimGrid, dimBlock>>>(gpu_pattern, gpu_buf, size_pattern, column, gpu_column);
        cudaDeviceSynchronize();
        
        printf(cudaGetErrorString(cudaPeekAtLastError()));

        cudaMemcpy(column, gpu_column, (size_pattern + 1) * sizeof(int), cudaMemcpyDeviceToHost);
        
        if (column[i] <= approx_factor)
        {
            n_matches[i]++;
        }
        free(column);
        cudaFree(gpu_column);
        cudaFree(gpu_buf);
        cudaFree(gpu_pattern);
    }

    /* Timer stop */
    gettimeofday(&t2, NULL);

    duration = (t2.tv_sec - t1.tv_sec) + ((t2.tv_usec - t1.tv_usec) / 1e6);

    printf("APM done in %lf s\n", duration);

    /*****
   * END MAIN LOOP
   ******/

    for (i = 0; i < nb_patterns; i++)
    {
        printf("Number of matches for pattern <%s>: %d\n",
               pattern[i], n_matches[i]);
    }

    return 0;
}
