#!/usr/bin/env python3
"""
Script for generating test matrices for PETSc GMRES solver
"""

import numpy as np
import scipy.sparse as sp
import argparse
import os
from pathlib import Path

def create_laplace_1d(n):
    """Create 1D Laplace matrix"""
    diag = 2.0 * np.ones(n)
    off_diag = -1.0 * np.ones(n-1)
    A = sp.diags([off_diag, diag, off_diag], [-1, 0, 1], format='csr')
    return A

def create_laplace_2d(nx, ny):
    """Create 2D Laplace matrix"""
    n = nx * ny
    A = sp.lil_matrix((n, n))
    
    for i in range(nx):
        for j in range(ny):
            index = i * ny + j
            
            # Diagonal
            A[index, index] = 4.0
            
            # Left neighbor
            if i > 0:
                A[index, index - ny] = -1.0
                
            # Right neighbor
            if i < nx - 1:
                A[index, index + ny] = -1.0
                
            # Bottom neighbor
            if j > 0:
                A[index, index - 1] = -1.0
                
            # Top neighbor
            if j < ny - 1:
                A[index, index + 1] = -1.0
    
    return A.tocsr()

def create_diagonal_dominant(n, dominance=1.0):
    """Create diagonal dominant matrix"""
    A = sp.random(n, n, density=0.1, format='csr')
    A = A + dominance * sp.eye(n)
    return A

def create_random_sparse(n, density=0.05):
    """Create random sparse matrix"""
    A = sp.random(n, n, density=density, format='csr')
    # Ensure diagonal dominance for better conditioning
    A = A + sp.eye(n)
    return A

def save_matrix_mm(A, filename):
    """Save matrix in Matrix Market format"""
    from scipy.io import mmwrite
    mmwrite(filename, A)

def save_matrix_petsc(A, filename):
    """Save matrix in PETSc binary format"""
    # This would require petsc4py - for future implementation
    print(f"PETSc binary format not implemented yet, saving as Matrix Market: {filename}.mtx")
    save_matrix_mm(A, f"{filename}.mtx")

def main():
    parser = argparse.ArgumentParser(description='Generate test matrices for PETSc GMRES solver')
    parser.add_argument('--type', choices=['laplace1d', 'laplace2d', 'diagonal', 'random'], 
                       default='laplace1d', help='Matrix type')
    parser.add_argument('--size', type=int, default=100, help='Matrix size (for 1D)')
    parser.add_argument('--nx', type=int, default=10, help='Grid size in x direction (for 2D)')
    parser.add_argument('--ny', type=int, default=10, help='Grid size in y direction (for 2D)')
    parser.add_argument('--density', type=float, default=0.05, help='Density for random matrices')
    parser.add_argument('--output', type=str, default='test_matrices', help='Output directory')
    parser.add_argument('--format', choices=['mm', 'petsc'], default='mm', help='Output format')
    
    args = parser.parse_args()
    
    # Create output directory
    output_dir = Path(args.output)
    output_dir.mkdir(exist_ok=True)
    
    # Generate matrix
    if args.type == 'laplace1d':
        A = create_laplace_1d(args.size)
        filename = output_dir / f"laplace1d_{args.size}.mtx"
    elif args.type == 'laplace2d':
        A = create_laplace_2d(args.nx, args.ny)
        filename = output_dir / f"laplace2d_{args.nx}x{args.ny}.mtx"
    elif args.type == 'diagonal':
        A = create_diagonal_dominant(args.size)
        filename = output_dir / f"diagonal_{args.size}.mtx"
    elif args.type == 'random':
        A = create_random_sparse(args.size, args.density)
        filename = output_dir / f"random_{args.size}_density{args.density}.mtx"
    
    # Save matrix
    if args.format == 'mm':
        save_matrix_mm(A, filename)
        print(f"Matrix saved as: {filename}")
    else:
        save_matrix_petsc(A, filename)
    
    # Print matrix info
    print(f"Matrix information:")
    print(f"  Size: {A.shape[0]} x {A.shape[1]}")
    print(f"  Non-zero elements: {A.nnz}")
    print(f"  Density: {A.nnz / (A.shape[0] * A.shape[1]):.4f}")
    
    # Estimate condition number for small matrices
    if A.shape[0] <= 1000:
        try:
            cond_num = np.linalg.cond(A.toarray())
            print(f"  Condition number: {cond_num:.2e}")
        except:
            print("  Condition number: Too large to compute")

if __name__ == "__main__":
    main()