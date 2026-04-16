#!/bin/bash

# Скрипт для сохранения всего кода Android Studio проекта в один файл

# Настройки
OUTPUT_FILE="full_code.txt"
EXCLUDE_DIRS=(
    ".gradle"
    ".idea"
    "build"
    ".git"
    ".svn"
    ".hg"
    "captures"
    "local"
    "generated"
    "intermediates"
    "tmp"
    "temp"
    ".build"
)

EXCLUDE_FILES=(
    "*.iml"
    "*.apk"
    "*.aab"
    "*.keystore"
    "*.jks"
    "*.class"
    "*.dex"
    "*.jar"
    "*.aar"
    "*.so"
    "*.o"
    "*.pyc"
    "*.swp"
    ".DS_Store"
    "Thumbs.db"
    "*.sh"
    "*.bat"
    "gradle-wrapper.properties"
    ".gitignore"
    "proguard-rules.pro"

)

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода сообщений
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Функция для проверки, нужно ли исключить директорию
should_exclude_dir() {
    local dir="$1"
    for exclude in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$dir" == *"/$exclude"* ]] || [[ "$dir" == "$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# Функция для проверки, нужно ли исключить файл
should_exclude_file() {
    local file="$1"
    for exclude in "${EXCLUDE_FILES[@]}"; do
        if [[ "$file" == *"${exclude/\*/}" ]] || [[ "$(basename "$file")" == ${exclude} ]]; then
            return 0
        fi
    done
    return 1
}

# Функция для определения типа файла по расширению
get_file_type() {
    case "$1" in
        *.java) echo "JAVA" ;;
        *.kt) echo "KOTLIN" ;;
        *.xml) echo "XML" ;;
        *.gradle) echo "GRADLE" ;;
        *.kts) echo "GRADLE_KTS" ;;
        *.properties) echo "PROPERTIES" ;;
        *.pro) echo "PROGUARD" ;;
        *.txt) echo "TEXT" ;;
        *.md) echo "MARKDOWN" ;;
        *.json) echo "JSON" ;;
        *.yaml|*.yml) echo "YAML" ;;
        *.cpp|*.c|*.h) echo "C_CPP" ;;
        *.cmake) echo "CMAKE" ;;
        *.py) echo "PYTHON" ;;
        *.sh) echo "SHELL" ;;
        *.js) echo "JAVASCRIPT" ;;
        *.ts) echo "TYPESCRIPT" ;;
        *.html|*.htm) echo "HTML" ;;
        *.css) echo "CSS" ;;
        *.svg) echo "SVG" ;;
        *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.ico) echo "IMAGE" ;;
        *.mp3|*.wav|*.ogg|*.m4a) echo "AUDIO" ;;
        *.mp4|*.avi|*.mov|*.mkv|*.webm) echo "VIDEO" ;;
        *.pdf) echo "PDF" ;;
        *.zip|*.tar|*.gz|*.rar|*.7z) echo "ARCHIVE" ;;
        *) echo "OTHER" ;;
    esac
}

# Основная функция
main() {
    log_info "Собираю весь код проекта в один файл..."
    
    # Удаляем старый файл, если существует
    if [ -f "$OUTPUT_FILE" ]; then
        rm "$OUTPUT_FILE"
        log_info "Удален старый файл $OUTPUT_FILE"
    fi
    
    # Добавляем заголовок
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "ПОЛНЫЙ ИСХОДНЫЙ КОД ANDROID STUDIO ПРОЕКТА" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "Дата создания: $(date)" >> "$OUTPUT_FILE"
    echo "Директория проекта: $(pwd)" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Счетчики
    TOTAL_FILES=0
    TOTAL_LINES=0
    PROCESSED_FILES=0
    SKIPPED_FILES=0
    
    # Находим все файлы
    log_info "Поиск файлов..."
    
    while IFS= read -r file; do
        TOTAL_FILES=$((TOTAL_FILES + 1))
    done < <(find . -type f)
    
    log_info "Найдено всего файлов: $TOTAL_FILES"
    
    # Обрабатываем файлы
    log_info "Обработка файлов..."
    
    find . -type f | while read -r file; do
        # Пропускаем сам выходной файл
        if [[ "$file" == "./$OUTPUT_FILE" ]] || [[ "$file" == "$OUTPUT_FILE" ]]; then
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            continue
        fi
        
        # Проверяем директорию
        if should_exclude_dir "$(dirname "$file")"; then
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            continue
        fi
        
        # Проверяем файл
        if should_exclude_file "$file"; then
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            continue
        fi
        
        # Получаем тип файла
        file_type=$(get_file_type "$file")
        
        # Пропускаем бинарные и медиа файлы
        case "$file_type" in
            IMAGE|AUDIO|VIDEO|PDF|ARCHIVE)
                SKIPPED_FILES=$((SKIPPED_FILES + 1))
                continue
                ;;
        esac
        
        # Пытаемся прочитать файл как текст
        if ! iconv -f UTF-8 "$file" -t UTF-8 -o /dev/null 2>/dev/null; then
            # Файл не является текстовым
            SKIPPED_FILES=$((SKIPPED_FILES + 1))
            continue
        fi
        
        # Обрабатываем файл
        PROCESSED_FILES=$((PROCESSED_FILES + 1))
        
        # Добавляем разделитель
        echo "" >> "$OUTPUT_FILE"
        echo "================================================================================" >> "$OUTPUT_FILE"
        echo "ФАЙЛ: ${file#./}" >> "$OUTPUT_FILE"
        echo "ТИП: $file_type" >> "$OUTPUT_FILE"
        echo "РАЗМЕР: $(du -h "$file" | cut -f1)" >> "$OUTPUT_FILE"
        echo "================================================================================" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Добавляем содержимое файла
        cat "$file" >> "$OUTPUT_FILE" 2>/dev/null
        
        # Добавляем пустую строку
        echo "" >> "$OUTPUT_FILE"
        
        # Считаем строки
        file_lines=$(wc -l < "$file" 2>/dev/null || echo "0")
        TOTAL_LINES=$((TOTAL_LINES + file_lines))
        
        # Выводим прогресс
        if [ $((PROCESSED_FILES % 10)) -eq 0 ]; then
            log_info "Обработано $PROCESSED_FILES файлов..."
        fi
    done
    
    # Добавляем статистику в конец файла
    echo "" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "СТАТИСТИКА" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    echo "Всего файлов в проекте: $TOTAL_FILES" >> "$OUTPUT_FILE"
    echo "Обработано файлов: $PROCESSED_FILES" >> "$OUTPUT_FILE"
    echo "Пропущено файлов: $SKIPPED_FILES" >> "$OUTPUT_FILE"
    echo "Всего строк кода: $TOTAL_LINES" >> "$OUTPUT_FILE"
    echo "Дата создания отчета: $(date)" >> "$OUTPUT_FILE"
    echo "================================================================================" >> "$OUTPUT_FILE"
    
    log_success "Готово!"
    log_info "Файл создан: $OUTPUT_FILE"
    log_info "Статистика:"
    log_info "  Всего файлов: $TOTAL_FILES"
    log_info "  Обработано: $PROCESSED_FILES"
    log_info "  Пропущено: $SKIPPED_FILES"
    log_info "  Всего строк: $TOTAL_LINES"
    log_info "  Размер файла: $(du -h "$OUTPUT_FILE" | cut -f1)"
}

# Обработка аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Использование: $0 [OPTIONS]"
            echo ""
            echo "Опции:"
            echo "  -o, --output FILE   Указать выходной файл (по умолчанию: full_code.txt)"
            echo "  -h, --help         Показать эту справку"
            echo ""
            echo "Примеры:"
            echo "  $0                  # Сохранить код в full_code.txt"
            echo "  $0 -o all_code.txt  # Сохранить код в all_code.txt"
            exit 0
            ;;
        *)
            log_error "Неизвестная опция: $1"
            echo "Используйте $0 --help для справки"
            exit 1
            ;;
    esac
done

# Запускаем основной скрипт
main
