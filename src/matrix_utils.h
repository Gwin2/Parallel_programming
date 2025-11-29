#ifndef MATRIX_UTILS_H
#define MATRIX_UTILS_H

#include <petscksp.h>

PetscErrorCode create_laplace_matrix(PetscInt n, Mat *A);
PetscErrorCode create_diagonal_dominant_matrix(PetscInt n, PetscReal diagonal_value, Mat *A);
PetscErrorCode create_random_sparse_matrix(PetscInt n, PetscReal density, Mat *A);
PetscErrorCode create_rhs_vector(PetscInt n, Vec *b);
PetscErrorCode read_matrix_from_file(const char *filename, Mat *A);
PetscErrorCode write_matrix_to_file(const char *filename, Mat A);
PetscErrorCode print_matrix_info(Mat A, const char *name);

#endif