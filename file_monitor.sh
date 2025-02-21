#!/bin/bash
# Скрипт для автоматического детектирования процессов, создающих подозрительные файлы

# Конфигурация
TARGET_DIR="/home/user"              # Директория для мониторинга
FILE_PATTERNS="re|sys|os|gi|gettext|rfkillMagic|setproctitle"  # Шаблоны имен файлов
LOG_FILE="/var/log/file_monitor.log" # Путь к лог-файлу
MAX_LOG_SIZE=1048576                # Максимальный размер лога (1MB)
LOCK_FILE="/tmp/file_monitor.lock"   # Файл блокировки

# Проверка прав администратора
if [ "$EUID" -ne 0 ]; then
  echo "Для работы скрипта требуются права root. Запустите с sudo!" >&2
  exit 1
fi

# Создание файла блокировки
if [ -f "$LOCK_FILE" ]; then
  echo "Скрипт уже запущен (PID: $(cat $LOCK_FILE))" >&2
  exit 1
fi
echo $$ > "$LOCK_FILE"

# Обработка прерывания
trap 'rm -f "$LOCK_FILE"; exit 0' INT TERM EXIT

# Функция логирования
log_event() {
  local message="$1"
  local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
  
  # Ротация логов
  if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
    mv "$LOG_FILE" "${LOG_FILE}.old"
  fi
  
  echo "[$timestamp] $message" | tee -a "$LOG_FILE"
}

# Функция анализа процессов
analyze_process() {
  local file_path="$1"
  local attempts=3
  local pid=""
  
  # Несколько попыток найти процесс
  for ((i=1; i<=attempts; i++)); do
    pid=$(lsof -t "$file_path" 2>/dev/null | head -n1)
    [ -n "$pid" ] && break
    sleep 0.5
  done

  if [ -n "$pid" ]; then
    # Детальная информация о процессе
    local proc_info=$(ps -p "$pid" -o pid=,user=,ppid=,comm=,cmd=)
    local connections=$(lsof -Pan -p "$pid" -i 2>/dev/null)
    local children=$(pstree -p "$pid")
    
    log_event "Обнаружен процесс-создатель:
PID:           $pid
Информация:    $proc_info
Родительский:  $(ps -o ppid= -p $pid)
Дочерние:      $children
Соединения:    ${connections:-Нет сетевых соединений}"
  else
    # Поиск в журнале аудита
    local audit_info=$(ausearch -k file_monitor -ts recent 2>/dev/null | grep "$file_path")
    log_event "Файл создан, но процесс не найден. Аудит: ${audit_info:-Нет данных}"
  fi
}

# Настройка аудита
setup_audit() {
  auditctl -D >/dev/null 2>&1  # Очистка старых правил
  auditctl -w "$TARGET_DIR" -p w -k file_monitor
}

# Основной мониторинг
main_monitor() {
  log_event "Старт мониторинга директории $TARGET_DIR"
  setup_audit
  
  inotifywait -m -q -e create --format "%w%f" "$TARGET_DIR" | while read -r file_path; do
    file_name=$(basename "$file_path")
    
    if [[ "$file_name" =~ $FILE_PATTERNS ]]; then
      log_event "Обнаружен подозрительный файл: $file_path"
      analyze_process "$file_path"
      
      # Дополнительные действия (раскомментировать при необходимости)
      # rm -f "$file_path"
      # pkill -P "$pid"
    fi
  done
}

# Запуск основной функции
main_monitor
