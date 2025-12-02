#!/bin/bash

set -e

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции для вывода
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Переменные
OUTPUT_DIR="benchmark_results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="$OUTPUT_DIR/results_$TIMESTAMP.csv"
PROCS=4

# Создание директории для результатов
mkdir -p $OUTPUT_DIR

# Заголовок CSV файла
echo "matrix_size,processes,preconditioner,iterations,residual,solve_time" > $RESULTS_FILE

# Функция для запуска бенчмарка
run_benchmark() {
    local size=$1
    local procs=$2
    local pc=$3
    
    step "Running benchmark: size=$size, processes=$procs, preconditioner=$pc"
    
    # Запуск и парсинг результатов
    local output
    output=$(mpirun -np $procs ./petsc_solver -n $size -pc_type $pc -ksp_monitor -ksp_converged_reason 2>/dev/null)
    
    # Извлечение данных из вывода
    local iterations
    iterations=$(echo "$output" | grep "iterations" | awk '{print $NF}' | head -1)
    
    local residual
    residual=$(echo "$output" | grep "residual" | awk '{print $NF}' | head -1)
    
    local solve_time
    solve_time=$(echo "$output" | grep "Solve time" | awk '{print $NF}' | head -1)
    
    # Запись в CSV
    echo "$size,$procs,$pc,$iterations,$residual,$solve_time" >> $RESULTS_FILE
    
    info "Results: iterations=$iterations, residual=$residual, time=$solve_time"
}

# Основные бенчмарки
main_benchmarks() {
    info "Starting main benchmarks..."
    
    # Различные размеры матриц
    local sizes=(100 500 1000 2000)
    
    # Различные предобуславливатели
    local preconditioners=("jacobi" "ilu" "none")
    
    for size in "${sizes[@]}"; do
        for pc in "${preconditioners[@]}"; do
            run_benchmark $size $PROCS $pc
        done
    done
}

# Масштабируемость
scaling_benchmarks() {
    info "Starting scaling benchmarks..."
    
    local size=2000
    local proc_list=(1 2 4 8)
    
    for procs in "${proc_list[@]}"; do
        run_benchmark $size $procs "jacobi"
    done
}

# Сравнение предобуславливателей
preconditioner_benchmarks() {
    info "Starting preconditioner comparison..."
    
    local size=1000
    local preconditioners=("jacobi" "ilu" "none" "sor" "eisenstat")
    
    for pc in "${preconditioners[@]}"; do
        run_benchmark $size $PROCS $pc
    done
}

# Анализ результатов
analyze_results() {
    info "Analyzing benchmark results..."
    
    if command -v python3 &> /dev/null; then
        python3 << EOF
import pandas as pd
import matplotlib.pyplot as plt
import os

# Чтение результатов
df = pd.read_csv('$RESULTS_FILE')

print("=== Benchmark Results Summary ===")
print(f"Total runs: {len(df)}")
print(f"Best performance: {df['solve_time'].min():.3f} seconds")
print(f"Worst performance: {df['solve_time'].max():.3f} seconds")
print(f"Average iterations: {df['iterations'].mean():.1f}")

# Создание графиков
fig, axes = plt.subplots(2, 2, figsize=(12, 10))

# Время от размера матрицы
for pc in df['preconditioner'].unique():
    data = df[df['preconditioner'] == pc]
    axes[0,0].plot(data['matrix_size'], data['solve_time'], 'o-', label=pc)
axes[0,0].set_xlabel('Matrix Size')
axes[0,0].set_ylabel('Solve Time (s)')
axes[0,0].set_title('Solve Time vs Matrix Size')
axes[0,0].legend()
axes[0,0].grid(True)

# Итерации от размера матрицы
for pc in df['preconditioner'].unique():
    data = df[df['preconditioner'] == pc]
    axes[0,1].plot(data['matrix_size'], data['iterations'], 'o-', label=pc)
axes[0,1].set_xlabel('Matrix Size')
axes[0,1].set_ylabel('Iterations')
axes[0,1].set_title('Iterations vs Matrix Size')
axes[0,1].legend()
axes[0,1].grid(True)

# Масштабируемость
scaling_data = df[df['preconditioner'] == 'jacobi']
axes[1,0].plot(scaling_data['processes'], scaling_data['solve_time'], 'o-')
axes[1,0].set_xlabel('Processes')
axes[1,0].set_ylabel('Solve Time (s)')
axes[1,0].set_title('Strong Scaling')
axes[1,0].grid(True)

# Сравнение предобуславливателей
pc_data = df.groupby('preconditioner')['solve_time'].mean()
axes[1,1].bar(pc_data.index, pc_data.values)
axes[1,1].set_xlabel('Preconditioner')
axes[1,1].set_ylabel('Average Solve Time (s)')
axes[1,1].set_title('Preconditioner Comparison')
axes[1,1].grid(True)

plt.tight_layout()
plt.savefig('$OUTPUT_DIR/benchmark_plots_$TIMESTAMP.png', dpi=300, bbox_inches='tight')
print(f"Plots saved to: $OUTPUT_DIR/benchmark_plots_$TIMESTAMP.png")
EOF
    else
        warn "Python3 not available, skipping analysis"
    fi
}

# Обработка аргументов командной строки
case "${1:-}" in
    "--scaling")
        scaling_benchmarks
        ;;
    "--preconditioners")
        preconditioner_benchmarks
        ;;
    "--compare")
        main_benchmarks
        ;;
    *)
        main_benchmarks
        scaling_benchmarks
        preconditioner_benchmarks
        ;;
esac

analyze_results

info "Benchmarks completed! Results saved to: $RESULTS_FILE"
info "Summary file: $OUTPUT_DIR/benchmark_plots_$TIMESTAMP.png"