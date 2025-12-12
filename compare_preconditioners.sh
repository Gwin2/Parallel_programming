#!/bin/bash
# compare_preconditioners.sh - Сравнение предобуславливателей

SIZE=1000
PROCS=4
OUTPUT_FILE="benchmark_results/preconditioners_$(date +%Y%m%d_%H%M%S).txt"

echo "=== Сравнение предобуславливателей ===" > $OUTPUT_FILE
echo "Размер матрицы: $SIZE" >> $OUTPUT_FILE
echo "Процессы: $PROCS" >> $OUTPUT_FILE
echo "Дата: $(date)" >> $OUTPUT_FILE
echo "" >> $OUTPUT_FILE
echo "Предобуславливатель | Итерации | Время (сек) | Ускорение" >> $OUTPUT_FILE
echo "---------------------|----------|-------------|-----------" >> $OUTPUT_FILE

BASE_TIME=0
for pc in none jacobi ilu bjacobi; do
    echo "Тестирование предобуславливателя: $pc..."
    output=$(mpirun -np $PROCS ./petsc_solver -n $SIZE -pc_type $pc 2>&1)
    
    iterations=$(echo "$output" | grep "Iterations" | awk '{print $NF}')
    time=$(echo "$output" | grep "Solve time" | awk '{print $(NF-1)}')
    
    if [ "$pc" == "none" ]; then
        BASE_TIME=$time
        speedup="1.00"
    else
        speedup=$(echo "scale=2; $BASE_TIME / $time" | bc)
    fi
    
    printf "%20s | %9s | %11s | %9sx\n" $pc $iterations $time $speedup >> $OUTPUT_FILE
    printf "%20s | %9s | %11s | %9sx\n" $pc $iterations $time $speedup
done

echo ""
echo "Результаты сохранены в: $OUTPUT_FILE"

