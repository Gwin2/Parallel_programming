cmake_minimum_required(VERSION 3.10)
project(PETScGMRESSolver C)

# Настройка компилятора
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Поиск PETSc
find_package(PETSc REQUIRED)

# Включение директорий
include_directories(src)
include_directories(${PETSC_INCLUDES})

# Основной исполняемый файл
add_executable(petsc_solver
    src/main.c
    src/solver.c
    src/matrix_utils.c
)

# Тестовый исполняемый файл
add_executable(test_solver
    tests/test_solver.c
    src/solver.c
    src/matrix_utils.c
)

# Примеры
add_executable(poisson2d examples/poisson2d.c src/solver.c src/matrix_utils.c)
add_executable(heat_equation examples/heat_equation.c src/solver.c src/matrix_utils.c)
add_executable(read_matrix_file examples/read_matrix_file.c src/solver.c src/matrix_utils.c)

# Связывание с PETSc
target_link_libraries(petsc_solver ${PETSC_LIBRARIES})
target_link_libraries(test_solver ${PETSC_LIBRARIES})
target_link_libraries(poisson2d ${PETSC_LIBRARIES})
target_link_libraries(heat_equation ${PETSC_LIBRARIES})
target_link_libraries(read_matrix_file ${PETSC_LIBRARIES})

# Установка
install(TARGETS petsc_solver DESTINATION bin)
install(TARGETS test_solver DESTINATION tests)
install(TARGETS poisson2d heat_equation read_matrix_file DESTINATION examples)

# Тесты
enable_testing()
add_test(NAME test_solver COMMAND mpirun -np 2 test_solver)
add_test(NAME test_diagonal COMMAND mpirun -np 2 test_solver -test_diagonal)