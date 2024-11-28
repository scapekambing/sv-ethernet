CC=g++
CFLAGS=-Wall
LIBS = -lws2_32

all: client server

client: client.o
	$(CC) -o client client.o $(LIBS)

server: server.o
	$(CC) -o server server.o $(LIBS)

clean veryclean:
	$(RM)  client server