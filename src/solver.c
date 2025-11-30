#include "solver.h"
#include <petsctime.h>

PetscErrorCode solver_initialize(int argc, char **argv) {
    PetscErrorCode ierr;
    ierr = PetscInitialize(&argc, &argv, NULL, NULL); CHKERRQ(ierr);
    PetscPrintf(PETSC_COMM_WORLD, "=== PETSc GMRES Solver Initialized ===\n");
    return 0;
}

PetscErrorCode solver_finalize() {
    PetscErrorCode ierr;
    PetscPrintf(PETSC_COMM_WORLD, "=== PETSc GMRES Solver Finalized ===\n");
    ierr = PetscFinalize();
    return ierr;
}

PetscErrorCode solver_create(LinearSolver *solver, Mat A) {
    PetscErrorCode ierr;
    
    solver->A = A;
    ierr = MatGetSize(A, &solver->matrix_size, NULL); CHKERRQ(ierr);
    
    // Создание векторов
    ierr = VecCreate(PETSC_COMM_WORLD, &solver->b); CHKERRQ(ierr);
    ierr = VecSetSizes(solver->b, PETSC_DECIDE, solver->matrix_size); CHKERRQ(ierr);
    ierr = VecSetFromOptions(solver->b); CHKERRQ(ierr);
    
    ierr = VecDuplicate(solver->b, &solver->x); CHKERRQ(ierr);
    
    // Создание решателя KSP
    ierr = KSPCreate(PETSC_COMM_WORLD, &solver->ksp); CHKERRQ(ierr);
    ierr = KSPSetOperators(solver->ksp, A, A); CHKERRQ(ierr);
    ierr = KSPSetType(solver->ksp, KSPGMRES); CHKERRQ(ierr);
    
    // Получение предобуславливателя
    ierr = KSPGetPC(solver->ksp, &solver->pc); CHKERRQ(ierr);
    
    // Настройки по умолчанию
    ierr = KSPSetTolerances(solver->ksp, 1e-7, PETSC_DEFAULT, PETSC_DEFAULT, 1000); CHKERRQ(ierr);
    
    solver->iterations = 0;
    solver->residual = 0.0;
    solver->solve_time = 0.0;
    
    return 0;
}

PetscErrorCode solver_set_preconditioner(LinearSolver *solver, PCType pc_type) {
    PetscErrorCode ierr;
    ierr = PCSetType(solver->pc, pc_type); CHKERRQ(ierr);
    return 0;
}

PetscErrorCode solver_set_tolerances(LinearSolver *solver, PetscReal rtol, PetscReal atol, PetscReal dtol, PetscInt maxits) {
    PetscErrorCode ierr;
    ierr = KSPSetTolerances(solver->ksp, rtol, atol, dtol, maxits); CHKERRQ(ierr);
    return 0;
}

PetscErrorCode solver_setup(LinearSolver *solver) {
    PetscErrorCode ierr;
    ierr = KSPSetUp(solver->ksp); CHKERRQ(ierr);
    return 0;
}

PetscErrorCode solver_solve(LinearSolver *solver, Vec b, Vec x) {
    PetscErrorCode ierr;
    PetscLogDouble start_time, end_time;
    
    ierr = PetscTime(&start_time); CHKERRQ(ierr);
    ierr = KSPSolve(solver->ksp, b, x); CHKERRQ(ierr);
    ierr = PetscTime(&end_time); CHKERRQ(ierr);
    
    // Сохранение информации о решении
    ierr = KSPGetIterationNumber(solver->ksp, &solver->iterations); CHKERRQ(ierr);
    ierr = KSPGetResidualNorm(solver->ksp, &solver->residual); CHKERRQ(ierr);
    solver->solve_time = end_time - start_time;
    
    return 0;
}

PetscErrorCode solver_solve_with_result(LinearSolver *solver, Vec b, Vec x, SolverResult *result) {
    PetscErrorCode ierr;
    
    ierr = solver_solve(solver, b, x); CHKERRQ(ierr);
    
    // Заполнение структуры результата
    result->matrix_size = solver->matrix_size;
    result->iterations = solver->iterations;
    result->residual = solver->residual;
    result->solve_time = solver->solve_time;
    
    KSPConvergedReason reason;
    ierr = KSPGetConvergedReason(solver->ksp, &reason); CHKERRQ(ierr);
    result->converged = (reason > 0);
    
    return 0;
}

PetscErrorCode solver_destroy(LinearSolver *solver) {
    PetscErrorCode ierr;
    if (solver->ksp) { ierr = KSPDestroy(&solver->ksp); CHKERRQ(ierr); }
    if (solver->b) { ierr = VecDestroy(&solver->b); CHKERRQ(ierr); }
    if (solver->x) { ierr = VecDestroy(&solver->x); CHKERRQ(ierr); }
    return 0;
}

PetscErrorCode solver_print_info(LinearSolver *solver) {
    PetscErrorCode ierr;
    PetscPrintf(PETSC_COMM_WORLD, "=== Solver Information ===\n");
    PetscPrintf(PETSC_COMM_WORLD, "Matrix size: %" PetscInt_FMT "\n", solver->matrix_size);
    PetscPrintf(PETSC_COMM_WORLD, "Iterations: %" PetscInt_FMT "\n", solver->iterations);
    PetscPrintf(PETSC_COMM_WORLD, "Final residual: %g\n", solver->residual);
    PetscPrintf(PETSC_COMM_WORLD, "Solve time: %g seconds\n", solver->solve_time);
    ierr = KSPView(solver->ksp, PETSC_VIEWER_STDOUT_WORLD); CHKERRQ(ierr);
    return 0;
}

PetscErrorCode solver_benchmark(Mat A, Vec b, Vec x, PCType pc_type, SolverResult *result) {
    PetscErrorCode ierr;
    LinearSolver solver;
    PetscLogDouble setup_start, setup_end;
    
    ierr = PetscTime(&setup_start); CHKERRQ(ierr);
    ierr = solver_create(&solver, A); CHKERRQ(ierr);
    ierr = solver_set_preconditioner(&solver, pc_type); CHKERRQ(ierr);
    ierr = solver_setup(&solver); CHKERRQ(ierr);
    ierr = PetscTime(&setup_end); CHKERRQ(ierr);
    
    result->setup_time = setup_end - setup_start;
    
    ierr = solver_solve_with_result(&solver, b, x, result); CHKERRQ(ierr);
    ierr = solver_destroy(&solver); CHKERRQ(ierr);
    
    return 0;
}