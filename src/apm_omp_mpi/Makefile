SRC_DIR=src
HEADER_DIR=/usr/lib/x86_64-linux-gnu/openmpi/include
OBJ_DIR=obj

CC=gcc
CFLAGS=-O3 -I$(HEADER_DIR)
LDFLAGS=

SRC= apm.c

OBJ= $(OBJ_DIR)/apm.o

all: $(OBJ_DIR) apm

$(OBJ_DIR):
	mkdir $(OBJ_DIR)

$(OBJ_DIR)/%.o : $(SRC_DIR)/%.c
	$(CC) -fopenmp $(CFLAGS) -c -o $@ $^

apm:$(OBJ)
	$(CC) -fopenmp $(CFLAGS) $(LDFLAGS) -o $@ $^

clean:
	rm -f apm $(OBJ)
