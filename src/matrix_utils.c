#include "matrix_utils.h"
#include <petscmat.h>

PetscErrorCode create_laplace_matrix(PetscInt n, Mat *A) {
    PetscErrorCode ierr;
    PetscInt i, Istart, Iend;
    PetscScalar v[3];
    PetscInt col[3];
    
    ierr = MatCreate(PETSC_COMM_WORLD, A); CHKERRQ(ierr);
    ierr = MatSetSizes(*A, PETSC_DECIDE, PETSC_DECIDE, n, n); CHKERRQ(ierr);
    ierr = MatSetFromOptions(*A); CHKERRQ(ierr);
    ierr = MatSetUp(*A); CHKERRQ(ierr);
    
    ierr = MatGetOwnershipRange(*A, &Istart, &Iend); CHKERRQ(ierr);
    
    for (i = Istart; i < Iend; i++) {
        if (i == 0) {
            v[0] = 2.0; col[0] = 0;
            v[1] = -1.0; col[1] = 1;
            ierr = MatSetValues(*A, 1, &i, 2, col, v, INSERT_VALUES); CHKERRQ(ierr);
        } else if (i == n-1) {
            v[0] = -1.0; col[0] = n-2;
            v[1] = 2.0; col[1] = n-1;
            ierr = MatSetValues(*A, 1, &i, 2, col, v, INSERT_VALUES); CHKERRQ(ierr);
        } else {
            v[0] = -1.0; col[0] = i-1;
            v[1] = 2.0; col[1] = i;
            v[2] = -1.0; col[2] = i+1;
            ierr = MatSetValues(*A, 1, &i, 3, col, v, INSERT_VALUES); CHKERRQ(ierr);
        }
    }
    
    ierr = MatAssemblyBegin(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    
    return 0;
}

PetscErrorCode create_diagonal_dominant_matrix(PetscInt n, PetscReal diagonal_value, Mat *A) {
    PetscErrorCode ierr;
    PetscInt i, Istart, Iend;
    
    ierr = MatCreate(PETSC_COMM_WORLD, A); CHKERRQ(ierr);
    ierr = MatSetSizes(*A, PETSC_DECIDE, PETSC_DECIDE, n, n); CHKERRQ(ierr);
    ierr = MatSetFromOptions(*A); CHKERRQ(ierr);
    ierr = MatSetUp(*A); CHKERRQ(ierr);
    
    ierr = MatGetOwnershipRange(*A, &Istart, &Iend); CHKERRQ(ierr);
    
    for (i = Istart; i < Iend; i++) {
        PetscScalar value = diagonal_value;
        ierr = MatSetValue(*A, i, i, value, INSERT_VALUES); CHKERRQ(ierr);
    }
    
    ierr = MatAssemblyBegin(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    
    return 0;
}

PetscErrorCode create_random_sparse_matrix(PetscInt n, PetscReal density, Mat *A) {
    PetscErrorCode ierr;
    PetscInt i, j, Istart, Iend;
    PetscRandom rctx;
    
    ierr = MatCreate(PETSC_COMM_WORLD, A); CHKERRQ(ierr);
    ierr = MatSetSizes(*A, PETSC_DECIDE, PETSC_DECIDE, n, n); CHKERRQ(ierr);
    ierr = MatSetFromOptions(*A); CHKERRQ(ierr);
    ierr = MatSetUp(*A); CHKERRQ(ierr);
    
    ierr = PetscRandomCreate(PETSC_COMM_WORLD, &rctx); CHKERRQ(ierr);
    ierr = PetscRandomSetFromOptions(rctx); CHKERRQ(ierr);
    
    ierr = MatGetOwnershipRange(*A, &Istart, &Iend); CHKERRQ(ierr);
    
    for (i = Istart; i < Iend; i++) {
        for (j = 0; j < n; j++) {
            if ((PetscReal)rand() / RAND_MAX < density) {
                PetscScalar value;
                ierr = PetscRandomGetValue(rctx, &value); CHKERRQ(ierr);
                ierr = MatSetValue(*A, i, j, value, INSERT_VALUES); CHKERRQ(ierr);
            }
        }
        // Ensure diagonal dominance
        PetscScalar diag_value;
        ierr = PetscRandomGetValue(rctx, &diag_value); CHKERRQ(ierr);
        ierr = MatSetValue(*A, i, i, diag_value + n, INSERT_VALUES); CHKERRQ(ierr);
    }
    
    ierr = MatAssemblyBegin(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    
    ierr = PetscRandomDestroy(&rctx); CHKERRQ(ierr);
    return 0;
}

PetscErrorCode create_rhs_vector(PetscInt n, Vec *b) {
    PetscErrorCode ierr;
    PetscInt i, Istart, Iend;
    
    ierr = VecCreate(PETSC_COMM_WORLD, b); CHKERRQ(ierr);
    ierr = VecSetSizes(*b, PETSC_DECIDE, n); CHKERRQ(ierr);
    ierr = VecSetFromOptions(*b); CHKERRQ(ierr);
    
    ierr = VecGetOwnershipRange(*b, &Istart, &Iend); CHKERRQ(ierr);
    
    for (i = Istart; i < Iend; i++) {
        PetscScalar value = 1.0; // Uniform right-hand side
        ierr = VecSetValue(*b, i, value, INSERT_VALUES); CHKERRQ(ierr);
    }
    
    ierr = VecAssemblyBegin(*b); CHKERRQ(ierr);
    ierr = VecAssemblyEnd(*b); CHKERRQ(ierr);
    
    return 0;
}

PetscErrorCode print_matrix_info(Mat A, const char *name) {
    PetscErrorCode ierr;
    PetscInt m, n;
    MatType type;
    MatInfo info;
    
    ierr = MatGetSize(A, &m, &n); CHKERRQ(ierr);
    ierr = MatGetType(A, &type); CHKERRQ(ierr);
    ierr = MatGetInfo(A, MAT_GLOBAL_SUM, &info); CHKERRQ(ierr);
    
    PetscPrintf(PETSC_COMM_WORLD, "Matrix %s: %" PetscInt_FMT " x %" PetscInt_FMT ", type: %s, nonzeros: %" PetscInt_FMT "\n", 
                name, m, n, type, (PetscInt)info.nz_used);
    return 0;
}