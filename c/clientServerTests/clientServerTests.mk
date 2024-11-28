CC=x86_64-w64-mingw32-g++
CFLAGS=-Wall
LIBS = -lws2_32
TARGET = target
BUILD = build
PROG = client server
OBJS = $(addprefix $(BUILD)/, client.o server.o)

all: $(PROG)

$(BUILD)/%.o: %.cpp %.hpp
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJS): | $(BUILD)

$(BUILD):
	mkdir $(BUILD) $(TARGET)

$(PROG): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET)/$@ $(addprefix $(BUILD)/, $@.o) $(LIBS)

$(BUILD)/%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@