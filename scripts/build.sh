#!/bin/bash

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Функции для вывода
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Переменные
BUILD_TYPE="Release"
CHECK_DEPS=false
CLEAN_BUILD=false

# Разбор аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            BUILD_TYPE="Debug"
            shift
            ;;
        --check-deps)
            CHECK_DEPS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Проверка зависимостей
check_dependencies() {
    info "Checking dependencies..."
    
    # Проверка компилятора C
    if ! command -v mpicc &> /dev/null; then
        error "MPI C compiler (mpicc) not found"
        exit 1
    fi
    
    # Проверка PETSc
    if ! pkg-config --exists petsc; then
        if [ -z "$PETSC_DIR" ]; then
            error "PETSc not found and PETSC_DIR not set"
            exit 1
        else
            info "Using PETSc from: $PETSC_DIR"
        fi
    else
        info "PETSc found via pkg-config"
    fi
    
    # Проверка Make или CMake
    if command -v cmake &> /dev/null; then
        info "CMake found"
        USE_CMAKE=true
    elif command -v make &> /dev/null; then
        info "Make found"
        USE_CMAKE=false
    else
        error "Neither CMake nor Make found"
        exit 1
    fi
}

# Сборка с помощью Make
build_with_make() {
    info "Building with Make..."
    
    if [ "$CLEAN_BUILD" = true ]; then
        make clean
    fi
    
    if [ "$BUILD_TYPE" = "Debug" ]; then
        make CFLAGS="-Wall -O0 -g -std=c99"
    else
        make
    fi
}

# Сборка с помощью CMake
build_with_cmake() {
    info "Building with CMake..."
    
    if [ "$CLEAN_BUILD" = true ] && [ -d "build" ]; then
        rm -rf build
    fi
    
    mkdir -p build
    cd build
    
    if [ "$BUILD_TYPE" = "Debug" ]; then
        cmake -DCMAKE_BUILD_TYPE=Debug ..
    else
        cmake -DCMAKE_BUILD_TYPE=Release ..
    fi
    
    make -j$(nproc)
    cd ..
}

# Основная функция
main() {
    info "Starting PETSc GMRES Solver build..."
    
    if [ "$CHECK_DEPS" = true ]; then
        check_dependencies
    fi
    
    if [ "$USE_CMAKE" = true ]; then
        build_with_cmake
    else
        build_with_make
    fi
    
    # Проверка результатов сборки
    if [ -f "petsc_solver" ] || [ -f "build/petsc_solver" ]; then
        info "Build completed successfully!"
        
        # Запуск быстрого теста
        info "Running quick test..."
        if command -v mpirun &> /dev/null; then
            if [ -f "petsc_solver" ]; then
                mpirun -np 2 ./petsc_solver -n 100 -ksp_monitor | grep -q "KSPSolve" && info "Test passed!" || warn "Test may have issues"
            else
                mpirun -np 2 ./build/petsc_solver -n 100 -ksp_monitor | grep -q "KSPSolve" && info "Test passed!" || warn "Test may have issues"
            fi
        else
            warn "mpirun not found, skipping test"
        fi
    else
        error "Build failed - executable not found"
        exit 1
    fi
}

# Запуск основной функции
main "$@"