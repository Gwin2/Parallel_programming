#include <petscksp.h>
#include "../src/solver.h"
#include "../src/matrix_utils.h"

PetscErrorCode create_poisson2d_matrix(PetscInt nx, PetscInt ny, Mat *A) {
    PetscErrorCode ierr;
    PetscInt n = nx * ny;
    PetscInt i, j, Istart, Iend;
    PetscScalar v[5];
    PetscInt col[5];
    
    ierr = MatCreate(PETSC_COMM_WORLD, A); CHKERRQ(ierr);
    ierr = MatSetSizes(*A, PETSC_DECIDE, PETSC_DECIDE, n, n); CHKERRQ(ierr);
    ierr = MatSetFromOptions(*A); CHKERRQ(ierr);
    ierr = MatSetUp(*A); CHKERRQ(ierr);
    
    ierr = MatGetOwnershipRange(*A, &Istart, &Iend); CHKERRQ(ierr);
    
    for (i = Istart; i < Iend; i++) {
        PetscInt ix = i % nx;
        PetscInt iy = i / nx;
        PetscInt count = 0;
        
        // Center
        v[count] = 4.0; col[count] = i; count++;
        
        // Left
        if (ix > 0) {
            v[count] = -1.0; col[count] = i - 1; count++;
        }
        
        // Right
        if (ix < nx - 1) {
            v[count] = -1.0; col[count] = i + 1; count++;
        }
        
        // Bottom
        if (iy > 0) {
            v[count] = -1.0; col[count] = i - nx; count++;
        }
        
        // Top
        if (iy < ny - 1) {
            v[count] = -1.0; col[count] = i + nx; count++;
        }
        
        ierr = MatSetValues(*A, 1, &i, count, col, v, INSERT_VALUES); CHKERRQ(ierr);
    }
    
    ierr = MatAssemblyBegin(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    
    return 0;
}

int main(int argc, char **argv) {
    PetscErrorCode ierr;
    LinearSolver solver;
    Mat A;
    Vec b, x;
    PetscInt nx = 50, ny = 50;
    PetscInt n;
    
    ierr = solver_initialize(argc, argv); CHKERRQ(ierr);
    
    // Получение параметров из командной строки
    ierr = PetscOptionsGetInt(NULL, NULL, "-nx", &nx, NULL); CHKERRQ(ierr);
    ierr = PetscOptionsGetInt(NULL, NULL, "-ny", &ny, NULL); CHKERRQ(ierr);
    
    n = nx * ny;
    PetscPrintf(PETSC_COMM_WORLD, "Solving 2D Poisson problem: %D x %D grid (%D unknowns)\n", nx, ny, n);
    
    // Создание матрицы и векторов
    ierr = create_poisson2d_matrix(nx, ny, &A); CHKERRQ(ierr);
    ierr = create_rhs_vector(n, &b); CHKERRQ(ierr);
    
    // Решение
    ierr = solver_create(&solver, A); CHKERRQ(ierr);
    ierr = solver_set_preconditioner(&solver, PCJACOBI); CHKERRQ(ierr);
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