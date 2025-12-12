#!/bin/bash
# weak_scaling.sh - Тест слабого масштабирования

BASE_SIZE=1000
PC_TYPE="jacobi"
OUTPUT_FILE="benchmark_results/weak_scaling_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Слабый масштабинг ===" > $OUTPUT_FILE
echo "Базовый размер: $BASE_SIZE" >> $OUTPUT_FILE
echo "Предобуславливатель: $PC_TYPE" >> $OUTPUT_FILE
echo "Дата: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Процессы | Размер матрицы | Время (сек) | Итерации | Эффективность" >> $OUTPUT_FILE
echo "---------|----------------|-------------|----------|---------------" >> $OUTPUT_FILE

BASE_TIME=0
for procs in 1 2 4 8; do
    size=$((BASE_SIZE * procs))
    echo "Запуск с $procs процессами, размер матрицы: $size..."
    output=$(mpirun -np $procs ./petsc_solver -n $size -pc_type $PC_TYPE 2>&1)
    
    time=$(echo "$output" | grep "Solve time" | awk '{print $(NF-1)}')
    iterations=$(echo "$output" | grep "Iterations" | awk '{print $NF}')
    
    if [ "$procs" -eq 1 ]; then
        BASE_TIME=$time
        efficiency="100.0"
    else
        efficiency=$(echo "scale=1; $BASE_TIME * 100 / $time" | bc)
    fi
    
    printf "%8d | %15d | %11s | %8s | %13s%%\n" $procs $size $time $iterations $efficiency >> $OUTPUT_FILE
    printf "%8d | %15d | %11s | %8s | %13s%%\n" $procs $size $time $iterations $efficiency
done

echo ""
echo "Результаты сохранены в: $OUTPUT_FILE"

