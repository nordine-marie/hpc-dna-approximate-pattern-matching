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

#include <mpi.h>
#include <omp.h>

#define APM_DEBUG 0

char * 
read_input_file( char * filename, int * size )
{
    char * buf ;
    off_t fsize;
    int fd = 0 ;
    int n_bytes = 1 ;

    /* Open the text file */
    fd = open( filename, O_RDONLY ) ;
    if ( fd == -1 ) 
    {
        fprintf( stderr, "Unable to open the text file <%s>\n", filename ) ;
        return NULL ;
    }


    /* Get the number of characters in the textfile */
    fsize = lseek(fd, 0, SEEK_END);
    lseek(fd, 0, SEEK_SET);

    /* TODO check return of lseek */

#if APM_DEBUG
    printf( "File length: %lld\n", fsize ) ;
#endif

    /* Allocate data to copy the target text */
    buf = (char *)malloc( fsize * sizeof ( char ) ) ;
    if ( buf == NULL ) 
    {
        fprintf( stderr, "Unable to allocate %lld byte(s) for main array\n",
                fsize ) ;
        return NULL ;
    }

    n_bytes = read( fd, buf, fsize ) ;
    if ( n_bytes != fsize ) 
    {
        fprintf( stderr, 
                "Unable to copy %lld byte(s) from text file (%d byte(s) copied)\n",
                fsize, n_bytes) ;
        return NULL ;
    }

#if APM_DEBUG
    printf( "Number of read bytes: %d\n", n_bytes ) ;
#endif

    *size = n_bytes ;


    close( fd ) ;


    return buf ;
}


#define MIN3(a, b, c) ((a) < (b) ? ((a) < (c) ? (a) : (c)) : ((b) < (c) ? (b) : (c)))

int levenshtein(char *s1, char *s2, int len, int * column) {
    unsigned int x, y, lastdiag, olddiag;

    for (y = 1; y <= len; y++)
    {
        column[y] = y;
    }
    for (x = 1; x <= len; x++) {
        column[0] = x;
        lastdiag = x-1 ;
        for (y = 1; y <= len; y++) {
            olddiag = column[y];
            column[y] = MIN3(
                    column[y] + 1, 
                    column[y-1] + 1, 
                    lastdiag + (s1[y-1] == s2[x-1] ? 0 : 1)
                    );
            lastdiag = olddiag;

        }
    }
    return(column[len]);
}




int 
main( int argc, char ** argv )
{
  /* MPI initialisation 
  */
  int nb_nodes;
  int rank; 
  MPI_Status status;
  MPI_Init(&argc, &argv);
  MPI_Comm_size(MPI_COMM_WORLD, &nb_nodes);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);

  #if APM_DEBUG
    char hostname[256];
    gethostname(hostname, sizeof(hostname));
    printf("Process MPI rank %d of PID %d on %s ready for attach\n",rank, getpid(), hostname);
  #endif

  char ** pattern ;
  char * filename ;
  int approx_factor = 0 ;
  int nb_patterns = 0 ;
  int i, j ;
  char * buf ;
  struct timeval t1, t2;
  double duration ;
  int n_bytes ;
  int tmp_matches ;
  int * n_matches ;
  int * global_matches;

  /* Check number of arguments */
  if ( argc < 4 ) 
  {
    printf( "Usage: %s approximation_factor "
            "dna_database pattern1 pattern2 ...\n", 
            argv[0] ) ;
    return 1 ;
  }

  /* Get the distance factor */
  approx_factor = atoi( argv[1] ) ;

  /* Grab the filename containing the target text */
  filename = argv[2] ;

  /* Get the number of patterns that the user wants to search for */
  nb_patterns = argc - 3 ;

  /* Fill the pattern array */
  pattern = (char **)malloc( nb_patterns * sizeof( char * ) ) ;
  if ( pattern == NULL ) 
  {
      fprintf( stderr, 
              "Unable to allocate array of pattern of size %d\n", 
              nb_patterns ) ;
      return 1 ;
  }

  /* Grab the patterns */
  int max_len_pattern = 0;
  for ( i = 0 ; i < nb_patterns ; i++ ) 
  {
      int l ;
      l = strlen(argv[i+3]) ;
      if ( l <= 0 ) 
      {
          fprintf( stderr, "Error while parsing argument %d\n", i+3 ) ;
          return 1 ;
      } else if (l > max_len_pattern)
      {
          max_len_pattern = l;
      }
      
      
      pattern[i] = (char *)malloc( (l+1) * sizeof( char ) ) ;
      if ( pattern[i] == NULL ) 
      {
          fprintf( stderr, "Unable to allocate string of size %d\n", l ) ;
          return 1 ;
      }

      strncpy( pattern[i], argv[i+3], (l+1) ) ;

  }


  printf( "Approximate Pattern Mathing: "
          "looking for %d pattern(s) in file %s w/ distance of %d\n", 
          nb_patterns, filename, approx_factor ) ;

  /* Allocate the array of local matches */
  n_matches = (int *)malloc( nb_patterns * sizeof( int ) ) ;
  if ( n_matches == NULL )
  {
      fprintf( stderr, "Error: unable to allocate memory for %ldB\n",
              nb_patterns * sizeof( int ) ) ;
      return 1 ;
  }

    /* Allocate the array of global matches for the reductin of local n_matches*/
  global_matches = (int *)malloc( nb_patterns * sizeof( int ) ) ;
  if ( global_matches == NULL )
  {
      fprintf( stderr, "Error: unable to allocate memory for %ldB\n",
              nb_patterns * sizeof( int ) ) ;
      return 1 ;
  }

  /*****
   * BEGIN MAIN LOOP
   ******/

  /* Timer start */
  gettimeofday(&t1, NULL);

  /* Since we have nb_nodes MPI process we are going to divide our textfile into 
     nb_nodes parts while taking care that the biggest pattern have access to all
     it needs.

     rank 0 treats from 0 to n_bytes//nb_nodes - 1 + (max_len_pattern - 1)
     rank 1 treats from n_bytes//nb_nodes to 2*(n_bytes//size) - 1 + (max_len_pattern - 1)
     .
     rank i treat from i*(n_bytes//nb_nodes) to (i+1)*(n_bytes//size) - 1 + (max_len_pattern - 1)
     .
     rank (nb_nodes-1) treat from (nb_nodes-1)*(n_bytes//nb_nodes) to END 
  */

  /* rank 0 play the role of divider */
  int part_bytes; // the number of bytes of the process part textfile
  MPI_Request requests[nb_nodes-1];
  MPI_Status statutes[nb_nodes-1];
  if (rank == 0) {
    /* reading input file */
    buf = read_input_file( filename, &n_bytes ) ;
    if ( buf == NULL )
    {
        return 1 ;
    }

    int start = 0; // start index of process
    int end = n_bytes/nb_nodes - 1 + (max_len_pattern - 1); // end index of process
    #if APM_DEBUG
        printf( "MPI rank 0 will treat from bytes %d to %d\n", start, end);
    #endif
    for (int i = 1; i < nb_nodes; i++) {
        /* Index and process part bytes */
        start += (n_bytes/nb_nodes);
        end += (n_bytes/nb_nodes);
        if (i == nb_nodes - 1 || end > n_bytes) {
            end = n_bytes;
        }
        part_bytes = end - start + 1 ;
        #if APM_DEBUG
            printf("MPI rank %d will treat from bytes %d to %d\n",i,start,end);
        #endif
        /* Sending to each process other than 0*/
        /* the part_bytes so they how much memory to allocate */
        MPI_Send(&part_bytes,1,MPI_INTEGER,i,0,MPI_COMM_WORLD);
        #if APM_DEBUG
            printf("Rank 0 sended part_bytes : %d to rank %d\n",part_bytes,i);
        #endif
        MPI_Send(&buf[start],part_bytes,MPI_BYTE,i,1,MPI_COMM_WORLD);
        #if APM_DEBUG
            printf("Rank 0 sended a part_buffer to rank %d\n",i);
        #endif
        /* the start & end index of their part */
    }
    // Reset part_bytes for process 0 :
    part_bytes = n_bytes/nb_nodes - 1 + max_len_pattern - 1; 
  } else {
      // other process receive :
      // first : part_bytes :
      MPI_Recv(&part_bytes,1,MPI_INTEGER,0,0,MPI_COMM_WORLD,&status);
      // so they know how much to allocate
      buf = (char *) malloc((part_bytes+1)*sizeof(char));
      if ( buf == NULL )
      {
        fprintf( stderr, "Unable to allocate %ld byte(s) for buf array\n",part_bytes);
        return -1;
      }
      // secondly : part textfile :
      MPI_Recv(buf,part_bytes,MPI_BYTE,0,1,MPI_COMM_WORLD,&status);
  }

  for ( i = 0 ; i < nb_patterns ; i++ )
  {
      int size_pattern = strlen(pattern[i]) ;

      int * column ;

      n_matches[i] = 0 ;

      tmp_matches = 0 ;

      #pragma omp parallel 
      {
        #pragma omp for schedule(guided) reduction(+:tmp_matches)
        for ( j = 0 ; (j < part_bytes - size_pattern + 1 && rank == 0) || (j < part_bytes && rank != 0)  ; j++ ) 
        {
            column = (int *)malloc( (size_pattern+1) * sizeof( int ) ) ;
            if ( column == NULL ) {
            fprintf( stderr, "Error: unable to allocate memory for column (%ldB)\n",
                    (size_pattern+1) * sizeof( int ) ) ;
            return 1 ;
            }

            int distance = 0 ;
            int size ;

    #if APM_DEBUG
            if ( j % 10000 == 0 )
            {
            printf( "MPI rank %d : Processing byte %d (out of %d)\n",rank, j, part_bytes ) ;
            printf("local matches of rank %d: ",rank);
            for (int i = 0; i < nb_patterns; i++)
            {
                printf("%d,",n_matches[i]);
            }
            printf("\n");
            
            }
    #endif

            size = size_pattern ;
            // modifying the edge case for the last MPI process
            if ( part_bytes - j < size_pattern )
            {
                size = part_bytes - j ;
            }

            distance = levenshtein( pattern[i], &buf[j], size, column ) ;

            if ( distance <= approx_factor ) {
                tmp_matches = tmp_matches + 1 ;
            }
        }
      }

  free( column );
  n_matches[i] = tmp_matches;
  }

  /* Sum the matches of each process with a MPI reduction */
  MPI_Reduce(n_matches, global_matches, nb_patterns, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
  
  /* Timer stop */
  gettimeofday(&t2, NULL);

  duration = (t2.tv_sec -t1.tv_sec)+((t2.tv_usec-t1.tv_usec)/1e6);
  #if APM_DEBUG
  printf("Rank %d finished  :",rank);
  for ( i = 0 ; i < nb_patterns ; i++ ) {
    printf( "%d, ",n_matches[i] ) ;
  }
  printf("=============\n");
  #endif
  

  /*****
   * END MAIN LOOP
   ******/

  if (rank == 0)
  {
    printf( "APM done in %lf s\n", duration ) ;
    for ( i = 0 ; i < nb_patterns ; i++ ) {
      printf( "Number of matches for pattern <%s>: %d\n", 
              pattern[i], global_matches[i] ) ;
    }
  }
  MPI_Finalize();
  return 0 ;
}
