#!/bin/bash
# tests/test_preconditioners.sh
# Тестирование различных предобуславливателей для PETSc GMRES решателя

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Проверка наличия необходимых файлов
check_requirements() {
    if [ ! -f "petsc_solver" ]; then
        error "Исполняемый файл petsc_solver не найден"
        error "Сначала выполните сборку: make"
        exit 1
    fi
    
    if ! command -v mpirun &> /dev/null; then
        error "mpirun не найден"
        exit 1
    fi
}

# Тестирование одного предобуславливателя
test_preconditioner() {
    local pc_type=$1
    local matrix_size=$2
    local processes=$3
    local output_file=$4
    
    step "Тестирование предобуславливателя: $pc_type, размер: $matrix_size, процессы: $processes"
    
    # Запуск решателя с указанным предобуславливателем
    local output
    output=$(mpirun -np $processes ./petsc_solver \
        -n $matrix_size \
        -pc_type $pc_type \
        -ksp_monitor \
        -ksp_converged_reason \
        -ksp_rtol 1e-7 \
        2>/dev/null || true)
    
    # Извлечение ключевых метрик
    local iterations
    iterations=$(echo "$output" | grep "iterations" | awk '{print $NF}' | head -1 || echo "N/A")
    
    local residual
    residual=$(echo "$output" | grep "residual" | awk '{print $NF}' | head -1 || echo "N/A")
    
    local solve_time
    solve_time=$(echo "$output" | grep "Solve time" | awk '{print $NF}' | head -1 || echo "N/A")
    
    local converged_reason
    converged_reason=$(echo "$output" | grep "Converged reason" | sed 's/.*reason: //' || echo "N/A")
    
    # Запись результатов
    echo "$pc_type,$matrix_size,$processes,$iterations,$residual,$solve_time,$converged_reason" >> "$output_file"
    
    # Вывод на экран
    if [ "$converged_reason" = "CONVERGED_RTOL" ] || [ "$converged_reason" = "CONVERGED_ATOL" ]; then
        info "Успех: $iterations итераций, невязка: $residual, время: $solve_time сек"
    else
        warn "Проблема со сходимостью: $converged_reason"
    fi
}

# Основная функция
main() {
    info "Начинаем тестирование предобуславливателей"
    
    check_requirements
    
    # Создаем директорию для результатов
    local result_dir="test_results/preconditioners"
    mkdir -p "$result_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$result_dir/results_$timestamp.csv"
    
    # Заголовок CSV файла
    echo "preconditioner,matrix_size,processes,iterations,residual,solve_time,converged_reason" > "$output_file"
    
    # Определяем параметры тестирования
    local matrix_sizes=(100 500 1000 2000)
    local processes_list=(1 2 4)
    local preconditioners=("none" "jacobi" "ilu" "bjacobi" "sor" "eisenstat")
    
    info "Тестируемые предобуславливатели: ${preconditioners[*]}"
    info "Размеры матриц: ${matrix_sizes[*]}"
    info "Количество процессов: ${processes_list[*]}"
    
    local total_tests=$(( ${#preconditioners[@]} * ${#matrix_sizes[@]} * ${#processes_list[@]} ))
    local current_test=0
    
    # Запуск всех тестов
    for pc in "${preconditioners[@]}"; do
        for size in "${matrix_sizes[@]}"; do
            for proc in "${processes_list[@]}"; do
                current_test=$((current_test + 1))
                info "Тест $current_test из $total_tests"
                test_preconditioner "$pc" "$size" "$proc" "$output_file"
                echo ""
            done
        done
    done
    
    # Анализ результатов
    analyze_results "$output_file"
    
    info "Тестирование завершено. Результаты сохранены в: $output_file"
}

# Анализ результатов
analyze_results() {
    local result_file=$1
    
    if [ ! -f "$result_file" ]; then
        warn "Файл результатов не найден для анализа"
        return
    fi
    
    step "Анализ результатов тестирования"
    
    # Используем Python для анализа если доступен
    if command -v python3 &> /dev/null; then
        python3 << EOF
import pandas as pd
import numpy as np
import sys

try:
    df = pd.read_csv('$result_file')
    
    print("\n=== Сводка по предобуславливателям ===")
    
    # Группировка по предобуславливателю
    summary = df.groupby('preconditioner').agg({
        'iterations': ['mean', 'std'],
        'solve_time': ['mean', 'std'],
        'converged_reason': lambda x: (x == 'CONVERGED_RTOL').sum() / len(x) * 100
    }).round(3)
    
    print(summary.to_string())
    
    # Нахождение лучшего предобуславливателя по времени
    best_by_time = df.loc[df['solve_time'] != 'N/A'].copy()
    best_by_time['solve_time'] = pd.to_numeric(best_by_time['solve_time'], errors='coerce')
    best_by_time = best_by_time.dropna(subset=['solve_time'])
    
    if not best_by_time.empty:
        idx = best_by_time['solve_time'].idxmin()
        best = best_by_time.loc[idx]
        print(f"\nЛучший предобуславливатель по времени:")
        print(f"  Тип: {best['preconditioner']}")
        print(f"  Размер: {best['matrix_size']}")
        print(f"  Процессы: {best['processes']}")
        print(f"  Время: {best['solve_time']:.3f} сек")
    
    # Статистика сходимости
    convergence_stats = df['converged_reason'].value_counts()
    print(f"\nСтатистика сходимости:")
    for reason, count in convergence_stats.items():
        percentage = count / len(df) * 100
        print(f"  {reason}: {count} ({percentage:.1f}%)")
        
except Exception as e:
    print(f"Ошибка при анализе результатов: {e}")
EOF
    else
        warn "Python3 не найден, пропускаем анализ"
    fi
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  -h, --help      Показать эту справку"
            echo "  --fast          Быстрое тестирование (только основные предобуславливатели)"
            echo "  --matrix-size   Размер матрицы (по умолчанию: 100 500 1000 2000)"
            echo "  --processes     Количество процессов (по умолчанию: 1 2 4)"
            exit 0
            ;;
        --fast)
            preconditioners=("none" "jacobi" "ilu")
            shift
            ;;
        *)
            warn "Неизвестный параметр: $1"
            exit 1
            ;;
    esac
done

# Запуск основной функции
main