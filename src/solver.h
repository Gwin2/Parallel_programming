#ifndef SOLVER_H
#define SOLVER_H

#include <petscksp.h>

typedef struct {
    KSP ksp;
    PC pc;
    Mat A;
    Vec x, b;
    PetscInt matrix_size;
    PetscInt iterations;
    PetscReal residual;
    PetscLogDouble solve_time;
} LinearSolver;

typedef struct {
    PetscInt matrix_size;
    PetscInt nonzeros;
    PetscInt iterations;
    PetscReal residual;
    PetscLogDouble setup_time;
    PetscLogDouble solve_time;
    PetscBool converged;
} SolverResult;

// Инициализация и финализация
PetscErrorCode solver_initialize(int argc, char **argv);
PetscErrorCode solver_finalize();

// Создание и настройка решателя
PetscErrorCode solver_create(LinearSolver *solver, Mat A);
PetscErrorCode solver_set_preconditioner(LinearSolver *solver, PCType pc_type);
PetscErrorCode solver_set_tolerances(LinearSolver *solver, PetscReal rtol, PetscReal atol, PetscReal dtol, PetscInt maxits);
PetscErrorCode solver_setup(LinearSolver *solver);

// Решение системы
PetscErrorCode solver_solve(LinearSolver *solver, Vec b, Vec x);
PetscErrorCode solver_solve_with_result(LinearSolver *solver, Vec b, Vec x, SolverResult *result);

// Утилиты
PetscErrorCode solver_destroy(LinearSolver *solver);
PetscErrorCode solver_print_info(LinearSolver *solver);
PetscErrorCode solver_benchmark(Mat A, Vec b, Vec x, PCType pc_type, SolverResult *result);

#endif