OS_NAME=tongseng
VERSION=0.1

CC=gcc

SRC_PATH=src
OBJ_PATH=obj
BIN_PATH=bin
INC_PATHS=

CCFLAGS=-DVERSION=\"$(VERSION)\"
LINKFLAG=

INCLUDES=$(addprefix -I,$(INC_PATHS))
C_FILES=$(wildcard $(SRC_PATH)/*.c)
OBJ_FILES=$(patsubst $(SRC_PATH)/%.c,$(OBJ_PATH)/%.o,$(C_FILES))

.PHONY: all clean
all: mkdir $(BIN_PATH)/$(OS_NAME)

mkdir: $(OBJ_PATH) $(BIN_PATH)

$(OBJ_PATH):
	mkdir -p $(OBJ_PATH)

$(BIN_PATH):
	mkdir -p $(BIN_PATH) 

$(BIN_PATH)/$(OS_NAME): $(OBJ_FILES)
	$(CC) -o $@ $^ $(LINKFLAG)

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.c $(SRC_PATH)/%.h
	$(CC) -o $@ -c $< $(CCFLAGS) -I$(SRC_PATH) $(INCLUDES)

$(OBJ_PATH)/%.o: $(SRC_PATH)/%.c
	$(CC) -o $@ -c $< $(CCFLAGS) -I$(SRC_PATH) $(INCLUDES)

clean:
	rm -rf $(OBJ_PATH) $(BIN_PATH)
