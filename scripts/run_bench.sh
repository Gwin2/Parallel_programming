# Полный набор бенчмарков
./scripts/run_benchmarks.sh

# Только масштабируемость
./scripts/run_benchmarks.sh --scaling

# Только предобуславливатели
./scripts/run_benchmarks.sh --preconditioners

# Сравнение производительности
./scripts/run_benchmarks.sh --compare