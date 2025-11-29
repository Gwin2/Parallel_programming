#!/bin/bash

set -e

echo "Building PETSc GMRES solver..."

# Проверка наличия PETSc
if ! pkg-config --exists petsc; then
    echo "PETSc not found. Please install PETSc first."
    exit 1
fi

# Создание директории сборки
mkdir -p build
cd build

# Конфигурация
cmake ..

# Компиляция
make -j$(nproc)

echo "Build completed successfully!"