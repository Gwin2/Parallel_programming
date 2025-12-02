#!/bin/bash

set -e

echo "Running PETSc GMRES solver tests..."

# Компиляция тестов
make test

# Запуск тестов
echo "=== Running basic tests ==="
mpirun -np 2 ./test_solver -ksp_monitor -ksp_converged_reason

echo "=== Testing different matrix sizes ==="
for size in 100 500 1000; do
    echo "Testing matrix size: $size"
    mpirun -np 2 ./petsc_solver -n $size -ksp_monitor | grep "Solve time"
done

echo "=== Testing preconditioners ==="
for pc in jacobi ilu none; do
    echo "Testing preconditioner: $pc"
    mpirun -np 2 ./petsc_solver -n 500 -pc_type $pc -ksp_monitor | grep "Iterations"
done

echo "All tests completed successfully!"