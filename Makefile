# Компилятор и флаги
CC = mpicc
CFLAGS = -Wall -O3 -std=c99
PETSC_DIR = $(shell pkg-config --variable=prefix petsc)
PETSC_ARCH = 
INCLUDE = -I./src $(shell pkg-config --cflags petsc)
LIBS = $(shell pkg-config --libs petsc)

# Цели
TARGET = petsc_solver
TEST_TARGET = test_solver
EXAMPLE_TARGETS = examples/poisson2d examples/heat_equation examples/read_matrix_file

# Исходные файлы
SRCS = src/main.c src/solver.c src/matrix_utils.c
TEST_SRCS = tests/test_solver.c src/solver.c src/matrix_utils.c
OBJS = $(SRCS:.c=.o)
TEST_OBJS = $(TEST_SRCS:.c=.o)

# Правила по умолчанию
all: $(TARGET) $(TEST_TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

$(TEST_TARGET): $(TEST_OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LIBS)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@

test: $(TEST_TARGET)
	mpirun -np 2 ./$(TEST_TARGET) -ksp_monitor

examples: $(EXAMPLE_TARGETS)

examples/%: examples/%.c $(filter-out src/main.o, $(OBJS))
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ $^ $(LIBS)

benchmark: $(TARGET)
	@echo "Running benchmarks..."
	./scripts/run_benchmarks.sh

clean:
	rm -f $(TARGET) $(TEST_TARGET) $(OBJS) $(TEST_OBJS) $(EXAMPLE_TARGETS)

install-deps:
	sudo apt-get update
	sudo apt-get install -y mpich libpetsc-dev petsc-dev cmake build-essential python3 python3-pip

install-python-deps:
	pip3 install -r requirements.txt

format:
	find src tests examples -name "*.c" -o -name "*.h" | xargs clang-format -i

.PHONY: all test examples benchmark clean install-deps install-python-deps format