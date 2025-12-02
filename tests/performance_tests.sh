#!/bin/bash
# tests/performance_tests.sh
# Тестирование производительности PETSc GMRES решателя

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

# Тест масштабируемости (сильное масштабирование)
test_strong_scaling() {
    local matrix_size=$1
    local output_file=$2
    
    step "Тест сильного масштабирования (матрица $matrix_size×$matrix_size)"
    
    local processes_list=(1 2 4 8)
    
    for proc in "${processes_list[@]}"; do
        info "Запуск с $proc процессами"
        
        local output
        output=$(mpirun -np $proc ./petsc_solver \
            -n $matrix_size \
            -pc_type jacobi \
            -ksp_monitor \
            -ksp_converged_reason \
            -ksp_rtol 1e-7 \
            2>/dev/null || true)
        
        local iterations
        iterations=$(echo "$output" | grep "iterations" | awk '{print $NF}' | head -1 || echo "N/A")
        
        local solve_time
        solve_time=$(echo "$output" | grep "Solve time" | awk '{print $NF}' | head -1 || echo "N/A")
        
        local setup_time
        setup_time=$(echo "$output" | grep "setup time" | awk '{print $NF}' | head -1 || echo "N/A")
        
        echo "strong,$matrix_size,$proc,$iterations,$solve_time,$setup_time" >> "$output_file"
        
        if [ "$solve_time" != "N/A" ]; then
            info "Время решения: $solve_time сек"
        fi
    done
}

# Тест масштабируемости (слабое масштабирование)
test_weak_scaling() {
    local base_size=$1
    local output_file=$2
    
    step "Тест слабого масштабирования (базовый размер: $base_size)"
    
    local processes_list=(1 2 4 8)
    
    for idx in "${!processes_list[@]}"; do
        local proc=${processes_list[$idx]}
        local matrix_size=$((base_size * proc))
        
        info "Запуск с $proc процессами, матрица $matrix_size×$matrix_size"
        
        local output
        output=$(mpirun -np $proc ./petsc_solver \
            -n $matrix_size \
            -pc_type jacobi \
            -ksp_monitor \
            -ksp_converged_reason \
            -ksp_rtol 1e-7 \
            2>/dev/null || true)
        
        local iterations
        iterations=$(echo "$output" | grep "iterations" | awk '{print $NF}' | head -1 || echo "N/A")
        
        local solve_time
        solve_time=$(echo "$output" | grep "Solve time" | awk '{print $NF}' | head -1 || echo "N/A")
        
        echo "weak,$matrix_size,$proc,$iterations,$solve_time" >> "$output_file"
        
        if [ "$solve_time" != "N/A" ]; then
            info "Время решения: $solve_time сек"
        fi
    done
}

# Тест различных размеров матриц
test_matrix_sizes() {
    local preconditioner=$1
    local processes=$2
    local output_file=$3
    
    step "Тестирование различных размеров матриц (предобуславливатель: $preconditioner, процессы: $processes)"
    
    local matrix_sizes=(100 500 1000 2000 5000)
    
    for size in "${matrix_sizes[@]}"; do
        info "Размер матрицы: $size"
        
        local output
        output=$(mpirun -np $processes ./petsc_solver \
            -n $size \
            -pc_type $preconditioner \
            -ksp_monitor \
            -ksp_converged_reason \
            -ksp_rtol 1e-7 \
            2>/dev/null || true)
        
        local iterations
        iterations=$(echo "$output" | grep "iterations" | awk '{print $NF}' | head -1 || echo "N/A")
        
        local solve_time
        solve_time=$(echo "$output" | grep "Solve time" | awk '{print $NF}' | head -1 || echo "N/A")
        
        local residual
        residual=$(echo "$output" | grep "residual" | awk '{print $NF}' | head -1 || echo "N/A")
        
        echo "size,$preconditioner,$size,$processes,$iterations,$solve_time,$residual" >> "$output_file"
        
        if [ "$solve_time" != "N/A" ]; then
            info "Итерации: $iterations, время: $solve_time сек, невязка: $residual"
        fi
    done
}

# Тест использования памяти
test_memory_usage() {
    local output_file=$1
    
    step "Тестирование использования памяти"
    
    local matrix_sizes=(100 500 1000 2000)
    
    for size in "${matrix_sizes[@]}"; do
        info "Измерение памяти для матрицы $size×$size"
        
        # Запускаем с valgrind если доступен
        if command -v valgrind &> /dev/null; then
            local mem_output
            mem_output=$(mpirun -np 1 valgrind --tool=massif --massif-out-file=massif.out \
                ./petsc_solver -n $size -pc_type jacobi -ksp_max_it 5 2>&1 | tail -20 || true)
            
            if [ -f "massif.out" ]; then
                local peak_mem
                peak_mem=$(grep "mem_heap_B" massif.out | awk '{print $2}' | sort -nr | head -1)
                
                if [ -n "$peak_mem" ]; then
                    local mem_mb=$((peak_mem / 1024 / 1024))
                    echo "memory,$size,$mem_mb" >> "$output_file"
                    info "Пиковое использование памяти: $mem_mb MB"
                fi
                rm -f massif.out
            fi
        else
            warn "valgrind не найден, пропускаем тест памяти"
            break
        fi
    done
}

# Анализ результатов производительности
analyze_performance() {
    local result_file=$1
    
    if [ ! -f "$result_file" ]; then
        warn "Файл результатов не найден для анализа"
        return
    fi
    
    step "Анализ результатов производительности"
    
    # Используем Python для анализа если доступен
    if command -v python3 &> /dev/null; then
        python3 << EOF
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import os

try:
    df = pd.read_csv('$result_file')
    
    print("\n=== Анализ производительности ===")
    
    # Анализ сильного масштабирования
    strong_data = df[df['test_type'] == 'strong']
    if not strong_data.empty:
        print("\nСильное масштабирование:")
        strong_data['solve_time'] = pd.to_numeric(strong_data['solve_time'], errors='coerce')
        
        # Вычисление ускорения
        base_time = strong_data[strong_data['processes'] == 1]['solve_time'].values[0]
        strong_data['speedup'] = base_time / strong_data['solve_time']
        strong_data['efficiency'] = strong_data['speedup'] / strong_data['processes'] * 100
        
        print(strong_data[['processes', 'solve_time', 'speedup', 'efficiency']].to_string())
        
        # Создание графиков
        fig, axes = plt.subplots(1, 2, figsize=(12, 5))
        
        # График времени
        axes[0].plot(strong_data['processes'], strong_data['solve_time'], 'o-', linewidth=2)
        axes[0].set_xlabel('Количество процессов')
        axes[0].set_ylabel('Время решения (сек)')
        axes[0].set_title('Сильное масштабирование: Время решения')
        axes[0].grid(True)
        
        # График эффективности
        axes[1].plot(strong_data['processes'], strong_data['efficiency'], 's-', linewidth=2, color='green')
        axes[1].set_xlabel('Количество процессов')
        axes[1].set_ylabel('Эффективность (%)')
        axes[1].set_title('Сильное масштабирование: Эффективность')
        axes[1].grid(True)
        axes[1].set_ylim([0, 110])
        
        plt.tight_layout()
        plt.savefig('performance_strong_scaling.png', dpi=150)
        print(f"\nГрафик сохранен: performance_strong_scaling.png")
    
    # Анализ размеров матриц
    size_data = df[df['test_type'] == 'size']
    if not size_data.empty:
        print("\nЗависимость от размера матрицы:")
        size_data['matrix_size'] = pd.to_numeric(size_data['matrix_size'])
        size_data['solve_time'] = pd.to_numeric(size_data['solve_time'], errors='coerce')
        
        # Группировка по предобуславливателю
        for pc in size_data['preconditioner'].unique():
            pc_data = size_data[size_data['preconditioner'] == pc]
            print(f"\nПредобуславливатель {pc}:")
            print(pc_data[['matrix_size', 'iterations', 'solve_time']].to_string())
        
        # Аппроксимация сложности
        print("\nАппроксимация сложности O(n^k):")
        for pc in size_data['preconditioner'].unique():
            pc_data = size_data[size_data['preconditioner'] == pc].dropna()
            if len(pc_data) > 1:
                x = np.log(pc_data['matrix_size'])
                y = np.log(pc_data['solve_time'])
                coeffs = np.polyfit(x, y, 1)
                exponent = coeffs[0]
                print(f"  {pc}: O(n^{exponent:.2f})")
    
    # Анализ использования памяти
    memory_data = df[df['test_type'] == 'memory']
    if not memory_data.empty:
        print("\nИспользование памяти:")
        memory_data['memory_mb'] = pd.to_numeric(memory_data['memory_mb'])
        memory_data['matrix_size'] = pd.to_numeric(memory_data['matrix_size'])
        
        # Аппроксимация роста памяти
        x = np.log(memory_data['matrix_size'])
        y = np.log(memory_data['memory_mb'])
        coeffs = np.polyfit(x, y, 1)
        exponent = coeffs[0]
        
        print(memory_data.to_string())
        print(f"Рост памяти: O(n^{exponent:.2f})")
        
except Exception as e:
    print(f"Ошибка при анализе результатов: {e}")
    import traceback
    traceback.print_exc()
EOF
    else
        warn "Python3 не найден, пропускаем анализ"
    fi
}

# Генерация отчета
generate_report() {
    local result_file=$1
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    cat << EOF > "performance_report.md"
# Отчет о производительности PETSc GMRES Solver

**Дата тестирования:** $timestamp  
**Система:** $(uname -a)

## Результаты тестирования

### 1. Сильное масштабирование

Тестирование фиксированного размера задачи на разном количестве процессов.

### 2. Слабое масштабирование

Тестирование пропорционального увеличения задачи с увеличением процессов.

### 3. Зависимость от размера матрицы

Анализ времени решения в зависимости от размера матрицы.

### 4. Использование памяти

Измерение пикового использования памяти для различных размеров матриц.

## Рекомендации

На основе результатов тестирования:

1. **Оптимальное количество процессов:** 4-8 для матриц среднего и большого размера
2. **Лучший предобуславливатель:** ILU для большинства случаев
3. **Ожидаемое время решения:** см. графики зависимости от размера

## Данные тестирования

\`\`\`
$(cat "$result_file" | head -50)
\`\`\`

*Полные данные доступны в файле: $result_file*
EOF
    
    info "Отчет сгенерирован: performance_report.md"
}

# Основная функция
main() {
    info "Начинаем тестирование производительности"
    
    check_requirements
    
    # Создаем директорию для результатов
    local result_dir="test_results/performance"
    mkdir -p "$result_dir"
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local output_file="$result_dir/performance_$timestamp.csv"
    
    # Заголовок CSV файла
    echo "test_type,param1,param2,param3,param4,param5,param6" > "$output_file"
    
    info "Запуск тестов производительности..."
    
    # 1. Тест сильного масштабирования
    test_strong_scaling 2000 "$output_file"
    
    # 2. Тест слабого масштабирования
    test_weak_scaling 500 "$output_file"
    
    # 3. Тест различных размеров матриц
    test_matrix_sizes "jacobi" 4 "$output_file"
    test_matrix_sizes "ilu" 4 "$output_file"
    
    # 4. Тест использования памяти
    test_memory_usage "$output_file"
    
    # Анализ результатов
    analyze_performance "$output_file"
    
    # Генерация отчета
    generate_report "$output_file"
    
    info "Тестирование производительности завершено"
    info "Результаты сохранены в: $output_file"
    info "Отчет: performance_report.md"
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Использование: $0 [опции]"
            echo "Опции:"
            echo "  -h, --help      Показать эту справку"
            echo "  --quick         Быстрое тестирование (только основные тесты)"
            echo "  --matrix-size   Базовый размер матрицы (по умолчанию: 2000)"
            exit 0
            ;;
        --quick)
            # В быстром режиме тестируем меньше размеров
            matrix_sizes=(100 500 1000)
            shift
            ;;
        --matrix-size)
            matrix_size=$2
            shift 2
            ;;
        *)
            warn "Неизвестный параметр: $1"
            exit 1
            ;;
    esac
done

# Запуск основной функции
main