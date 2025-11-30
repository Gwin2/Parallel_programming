#!/bin/bash

set -e

# Переход в директорию сборки
cd build

# Базовое использование
echo "Running PETSc solver with 4 processes, matrix size 1000..."
mpirun -np 4 ./petsc_solver -n 1000