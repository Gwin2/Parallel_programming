#!/bin/bash
# strong_scaling.sh - Тест сильного масштабирования

SIZE=2000
PC_TYPE="jacobi"
OUTPUT_FILE="benchmark_results/strong_scaling_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Сильный масштабинг ===" > $OUTPUT_FILE
echo "Размер матрицы: $SIZE" >> $OUTPUT_FILE
echo "Предобуславливатель: $PC_TYPE" >> $OUTPUT_FILE
echo "Дата: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Процессы | Время (сек) | Итерации | Ускорение | Эффективность" >> $OUTPUT_FILE
echo "---------|-------------|----------|-----------|---------------" >> $OUTPUT_FILE

BASE_TIME=0
for procs in 1 2 4 8; do
    echo "Запуск с $procs процессами..."
    output=$(mpirun -np $procs ./petsc_solver -n $SIZE -pc_type $PC_TYPE 2>&1)
    
    time=$(echo "$output" | grep "Solve time" | awk '{print $(NF-1)}')
    iterations=$(echo "$output" | grep "Iterations" | awk '{print $NF}')
    
    if [ "$procs" -eq 1 ]; then
        BASE_TIME=$time
        speedup="1.00"
        efficiency="100.0"
    else
        speedup=$(echo "scale=2; $BASE_TIME / $time" | bc)
        efficiency=$(echo "scale=1; $speedup * 100 / $procs" | bc)
    fi
    
    printf "%8d | %11s | %8s | %9s | %13s%%\n" $procs $time $iterations $speedup $efficiency >> $OUTPUT_FILE
    printf "%8d | %11s | %8s | %9s | %13s%%\n" $procs $time $iterations $speedup $efficiency
done

echo ""
echo "Результаты сохранены в: $OUTPUT_FILE"

