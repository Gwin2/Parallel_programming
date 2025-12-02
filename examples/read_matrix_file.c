#include <petscksp.h>
#include "../src/solver.h"
#include "../src/matrix_utils.h"

PetscErrorCode read_matrix_from_mm(const char *filename, Mat *A) {
    PetscErrorCode ierr;
    PetscViewer viewer;
    
    ierr = PetscViewerBinaryOpen(PETSC_COMM_WORLD, filename, FILE_MODE_READ, &viewer); CHKERRQ(ierr);
    ierr = MatCreate(PETSC_COMM_WORLD, A); CHKERRQ(ierr);
    ierr = MatSetFromOptions(*A); CHKERRQ(ierr);
    ierr = MatLoad(*A, viewer); CHKERRQ(ierr);
    ierr = PetscViewerDestroy(&viewer); CHKERRQ(ierr);
    
    return 0;
}

int main(int argc, char **argv) {
    PetscErrorCode ierr;
    LinearSolver solver;
    Mat A;
    Vec b, x;
    char filename[PETSC_MAX_PATH_LEN] = "matrix.m";
    
    ierr = solver_initialize(argc, argv); CHKERRQ(ierr);
    
    // Получение имени файла из командной строки
    ierr = PetscOptionsGetString(NULL, NULL, "-f", filename, PETSC_MAX_PATH_LEN, NULL); CHKERRQ(ierr);
    
    PetscPrintf(PETSC_COMM_WORLD, "Reading matrix from file: %s\n", filename);
    
    // Чтение матрицы из файла
    ierr = read_matrix_from_mm(filename, &A); CHKERRQ(ierr);
    
    // Получение размера матрицы
    PetscInt n, m;
    ierr = MatGetSize(A, &m, &n); CHKERRQ(ierr);
    
    if (m != n) {
        PetscPrintf(PETSC_COMM_WORLD, "Error: Matrix must be square\n");
        return 1;
    }
    
    // Создание правой части
    ierr = create_rhs_vector(n, &b); CHKERRQ(ierr);
    
    // Решение
    ierr = solver_create(&solver, A); CHKERRQ(ierr);
    ierr = solver_set_preconditioner(&solver, PCILU); CHKERRQ(ierr);
    ierr = solver_setup(&solver); CHKERRQ(ierr);
    
    ierr = solver_solve(&solver, b, solver.x); CHKERRQ(ierr);
    ierr = solver_print_info(&solver); CHKERRQ(ierr);
    
    // Очистка
    ierr = solver_destroy(&solver); CHKERRQ(ierr);
    ierr = MatDestroy(&A); CHKERRQ(ierr);
    ierr = VecDestroy(&b); CHKERRQ(ierr);
    
    ierr = solver_finalize();
    return ierr;
}