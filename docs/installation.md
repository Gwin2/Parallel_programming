# Установка и настройка

## Системные требования

### Минимальные требования
- **ОС**: Linux, macOS, или Windows (с WSL2)
- **Память**: 4 GB RAM
- **Диск**: 2 GB свободного места

### Рекомендуемые требования
- **ОС**: Linux (Ubuntu 20.04+ или CentOS 8+)
- **Память**: 8+ GB RAM
- **Диск**: 5+ GB свободного места
- **Процессоры**: Многоядерный процессор

## Установка зависимостей

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    mpich \
    libpetsc-dev \
    petsc-dev \
    python3 \
    python3-pip