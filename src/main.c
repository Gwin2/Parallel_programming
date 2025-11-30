#include <petscksp.h>
#include "solver.h"
#include "matrix_utils.h"

int main(int argc, char **argv) {
    PetscErrorCode ierr;
    LinearSolver solver;
    Mat A;
    Vec b;
    PetscInt matrix_size = 1000;
    char preconditioner[PETSC_MAX_PATH_LEN] = "jacobi";
    PetscBool test_mode = PETSC_FALSE, benchmark_mode = PETSC_FALSE;
    
    // Инициализация
    ierr = solver_initialize(argc, argv); CHKERRQ(ierr);
    
    // Обработка аргументов командной строки
    ierr = PetscOptionsGetInt(NULL, NULL, "-n", &matrix_size, NULL); CHKERRQ(ierr);
    ierr = PetscOptionsGetString(NULL, NULL, "-pc_type", preconditioner, PETSC_MAX_PATH_LEN, NULL); CHKERRQ(ierr);
    ierr = PetscOptionsGetBool(NULL, NULL, "-test", &test_mode, NULL); CHKERRQ(ierr);
    ierr = PetscOptionsGetBool(NULL, NULL, "-benchmark", &benchmark_mode, NULL); CHKERRQ(ierr);
    
    if (test_mode) {
        PetscPrintf(PETSC_COMM_WORLD, "Running in test mode...\n");
        // Здесь можно запустить тесты
    } else if (benchmark_mode) {
        PetscPrintf(PETSC_COMM_WORLD, "Running benchmarks...\n");
        // TODO: Implement run_benchmarks function
    } else {
        // Основной режим работы
        PetscPrintf(PETSC_COMM_WORLD, "Creating Laplace matrix of size %" PetscInt_FMT "...\n", matrix_size);
        ierr = create_laplace_matrix(matrix_size, &A); CHKERRQ(ierr);
        ierr = create_rhs_vector(matrix_size, &b); CHKERRQ(ierr);
        
        // Создание решателя
        ierr = solver_create(&solver, A); CHKERRQ(ierr);
        ierr = solver_set_preconditioner(&solver, preconditioner); CHKERRQ(ierr);
        ierr = solver_setup(&solver); CHKERRQ(ierr);
        
        // Решение системы
        ierr = solver_solve(&solver, b, solver.x); CHKERRQ(ierr);
        
        // Вывод информации
        ierr = solver_print_info(&solver); CHKERRQ(ierr);
        
        // Очистка
        ierr = solver_destroy(&solver); CHKERRQ(ierr);
        ierr = MatDestroy(&A); CHKERRQ(ierr);
        ierr = VecDestroy(&b); CHKERRQ(ierr);
    }
    
    ierr = solver_finalize();
    return ierr;
}