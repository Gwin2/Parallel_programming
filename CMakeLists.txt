cmake_minimum_required(VERSION 3.10)
project(PETSc_GMRES_Solver C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Find MPI (required for PETSc)
find_package(MPI REQUIRED)

# Try to find PETSc using pkg-config first, then fall back to manual search
find_package(PkgConfig QUIET)

if(PkgConfig_FOUND)
    pkg_check_modules(PETSC petsc)
endif()

# If pkg-config didn't find PETSc, try to find it manually
if(NOT PETSC_FOUND)
    message(STATUS "PETSc not found via pkg-config, trying manual search...")
    
    # Try common PETSc installation paths
    find_path(PETSC_INCLUDE_DIR petsc.h
        PATHS
        /usr/include/petsc
        /usr/local/include/petsc
        $ENV{PETSC_DIR}/include
        $ENV{PETSC_DIR}/$ENV{PETSC_ARCH}/include
    )
    
    find_library(PETSC_LIBRARY petsc
        PATHS
        /usr/lib
        /usr/local/lib
        /usr/lib/x86_64-linux-gnu
        $ENV{PETSC_DIR}/lib
        $ENV{PETSC_DIR}/$ENV{PETSC_ARCH}/lib
    )
    
    if(PETSC_INCLUDE_DIR AND PETSC_LIBRARY)
        set(PETSC_FOUND TRUE)
        set(PETSC_INCLUDE_DIRS ${PETSC_INCLUDE_DIR})
        set(PETSC_LIBRARIES ${PETSC_LIBRARY})
        set(PETSC_LIBRARY_DIRS "")
        set(PETSC_CFLAGS_OTHER "")
    endif()
endif()

if(NOT PETSC_FOUND)
    message(FATAL_ERROR "PETSc not found. Please install PETSc or set PETSC_DIR environment variable.")
endif()

# Include directories
include_directories(${PETSC_INCLUDE_DIRS})
include_directories(${MPI_C_INCLUDE_PATH})
include_directories(./src)

# Source files
set(SOURCES
    src/main.c
    src/solver.c
    src/matrix_utils.c
)

# Create executable
add_executable(petsc_solver ${SOURCES})

# Link libraries
target_link_directories(petsc_solver PRIVATE ${PETSC_LIBRARY_DIRS})
target_link_libraries(petsc_solver ${PETSC_LIBRARIES} ${MPI_C_LIBRARIES})
target_compile_options(petsc_solver PRIVATE ${PETSC_CFLAGS_OTHER} ${MPI_C_COMPILE_FLAGS})
target_include_directories(petsc_solver PRIVATE ${MPI_C_INCLUDE_PATH})

# Compiler flags
target_compile_options(petsc_solver PRIVATE -Wall -O3)

