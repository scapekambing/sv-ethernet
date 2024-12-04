CC=g++
CFLAGS=-Wall
OBJS = led_ctrl.o
ODIR = bin

all: led_ctrl

led-control: $(OBJS)
	$(CXX) -o led_ctrl led_ctrl.o

clean:
	-rm -f *.o $(OBJS)
