#!/bin/bash

set -e

echo "Building PETSc GMRES solver..."

# Проверка наличия cmake
if ! command -v cmake &> /dev/null; then
    echo "CMake not found. Please install CMake first."
    exit 1
fi

# Проверка наличия PETSc через pkg-config (опционально)
if command -v pkg-config &> /dev/null; then
    if ! pkg-config --exists petsc; then
        echo "Warning: PETSc not found via pkg-config. CMake will attempt to find it."
    else
        echo "PETSc found via pkg-config."
    fi
else
    echo "Warning: pkg-config not found. CMake will attempt to find PETSc."
fi

# Создание директории сборки (удаляем старую, если существует)
if [ -d build ]; then
    echo "Removing old build directory to avoid cache issues..."
    rm -rf build
fi
mkdir -p build

# Конфигурация (используем явное указание исходной и целевой директорий)
cmake -S . -B build

# Компиляция
cmake --build build --parallel $(nproc)

echo "Build completed successfully!"