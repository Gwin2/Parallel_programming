#include <petscksp.h>
#include "../src/solver.h"
#include "../src/matrix_utils.h"

PetscErrorCode create_heat_equation_matrix(PetscInt n, PetscReal alpha, Mat *A) {
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
            v[0] = 1.0 + 2.0 * alpha; col[0] = 0;
            v[1] = -alpha; col[1] = 1;
            ierr = MatSetValues(*A, 1, &i, 2, col, v, INSERT_VALUES); CHKERRQ(ierr);
        } else if (i == n-1) {
            v[0] = -alpha; col[0] = n-2;
            v[1] = 1.0 + 2.0 * alpha; col[1] = n-1;
            ierr = MatSetValues(*A, 1, &i, 2, col, v, INSERT_VALUES); CHKERRQ(ierr);
        } else {
            v[0] = -alpha; col[0] = i-1;
            v[1] = 1.0 + 2.0 * alpha; col[1] = i;
            v[2] = -alpha; col[2] = i+1;
            ierr = MatSetValues(*A, 1, &i, 3, col, v, INSERT_VALUES); CHKERRQ(ierr);
        }
    }

    ierr = MatAssemblyBegin(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);
    ierr = MatAssemblyEnd(*A, MAT_FINAL_ASSEMBLY); CHKERRQ(ierr);

    return 0;
}

int main(int argc, char **argv) {
    PetscErrorCode ierr;
    LinearSolver solver;
    Mat A;
    Vec b, x, initial;
    PetscInt n = 100;
    PetscReal alpha = 0.1;
    PetscReal dt = 0.01;

    ierr = solver_initialize(argc, argv); CHKERRQ(ierr);

    // Получение параметров из командной строки
    ierr = PetscOptionsGetInt(NULL, NULL, "-n", &n, NULL); CHKERRQ(ierr);
    ierr = PetscOptionsGetReal(NULL, NULL, "-alpha", &alpha, NULL); CHKERRQ(ierr);

    PetscPrintf(PETSC_COMM_WORLD, "Solving 1D heat equation: n=%D, alpha=%g\n", n, alpha);

    // Создание матрицы
    ierr = create_heat_equation_matrix(n, alpha, &A); CHKERRQ(ierr);

    // Начальное условие (синусоидальный профиль температуры)
    ierr = VecCreate(PETSC_COMM_WORLD, &initial); CHKERRQ(ierr);
    ierr = VecSetSizes(initial, PETSC_DECIDE, n); CHKERRQ(ierr);
    ierr = VecSetFromOptions(initial); CHKERRQ(ierr);

    PetscInt Istart, Iend;
    ierr = VecGetOwnershipRange(initial, &Istart, &Iend); CHKERRQ(ierr);

    for (PetscInt i = Istart; i < Iend; i++) {
        PetscScalar value = sin(2.0 * PETSC_PI * i / n);
        ierr = VecSetValue(initial, i, value, INSERT_VALUES); CHKERRQ(ierr);
    }
    ierr = VecAssemblyBegin(initial); CHKERRQ(ierr);
    ierr = VecAssemblyEnd(initial); CHKERRQ(ierr);

    // Правая часть
    ierr = VecDuplicate(initial, &b); CHKERRQ(ierr);
    ierr = VecCopy(initial, b); CHKERRQ(ierr);

    // Решение
    ierr = VecDuplicate(b, &x); CHKERRQ(ierr);

    ierr = solver_create(&solver, A); CHKERRQ(ierr);
    ierr = solver_set_preconditioner(&solver, PCILU); CHKERRQ(ierr);
    ierr = solver_setup(&solver); CHKERRQ(ierr);

    ierr = solver_solve(&solver, b, x); CHKERRQ(ierr);
    ierr = solver_print_info(&solver); CHKERRQ(ierr);

    // Очистка
    ierr = solver_destroy(&solver); CHKERRQ(ierr);
    ierr = MatDestroy(&A); CHKERRQ(ierr);
    ierr = VecDestroy(&b); CHKERRQ(ierr);
    ierr = VecDestroy(&x); CHKERRQ(ierr);
    ierr = VecDestroy(&initial); CHKERRQ(ierr);

    ierr = solver_finalize();
    return ierr;
}
