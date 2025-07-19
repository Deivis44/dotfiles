#!/bin/bash

# ==============================================================================
# SISTEMA DE TESTING PARA DOTFILES v2.0
# Suite de pruebas para validar la funcionalidad del sistema
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly TEST_LOG="$SCRIPT_DIR/test_results_$(date +%Y%m%d_%H%M%S).log"

# Contadores de pruebas
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# ==============================================================================
# FUNCIONES DE TESTING
# ==============================================================================

test_info() { echo -e "\033[36m[TEST]\033[0m $*" | tee -a "$TEST_LOG"; }
test_pass() { echo -e "\033[32m[PASS]\033[0m $*" | tee -a "$TEST_LOG"; ((TESTS_PASSED++)); }
test_fail() { echo -e "\033[31m[FAIL]\033[0m $*" | tee -a "$TEST_LOG"; ((TESTS_FAILED++)); }
test_skip() { echo -e "\033[33m[SKIP]\033[0m $*" | tee -a "$TEST_LOG"; }

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    test_info "Ejecutando: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        test_pass "$test_name"
        return 0
    else
        test_fail "$test_name"
        return 1
    fi
}

show_test_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════╗
║                    🧪 DOTFILES TESTING SUITE v2.0                   ║
║                   Validación del Sistema Completo                    ║
╚══════════════════════════════════════════════════════════════════════╝
EOF
}

# ==============================================================================
# PRUEBAS DE ARCHIVOS Y ESTRUCTURA
# ==============================================================================

test_file_structure() {
    test_info "🗂️  Probando estructura de archivos..."
    
    local required_files=(
        "packages.json"
        "package_installer.sh"
        "json_manager.sh"
        "full_installer_v2.sh"
        "migrate_to_json.sh"
    )
    
    for file in "${required_files[@]}"; do
        run_test "Archivo $file existe" "[[ -f '$SCRIPT_DIR/$file' ]]"
    done
    
    # Verificar permisos ejecutables
    local executable_files=(
        "package_installer.sh"
        "json_manager.sh"
        "full_installer_v2.sh"
        "migrate_to_json.sh"
    )
    
    for file in "${executable_files[@]}"; do
        run_test "Archivo $file es ejecutable" "[[ -x '$SCRIPT_DIR/$file' ]]"
    done
}

test_json_validity() {
    test_info "📄 Probando validez del JSON..."
    
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq no disponible, omitiendo pruebas JSON"
        return 0
    fi
    
    run_test "JSON sintácticamente válido" "jq empty '$SCRIPT_DIR/packages.json'"
    run_test "JSON tiene estructura 'categories'" "jq -e '.categories' '$SCRIPT_DIR/packages.json'"
    run_test "JSON tiene al menos una categoría" "jq -e '.categories | length > 0' '$SCRIPT_DIR/packages.json'"
    
    # Verificar que cada categoría tiene campos requeridos
    local categories_count
    categories_count=$(jq '.categories | length' "$SCRIPT_DIR/packages.json")
    
    if [[ $categories_count -gt 0 ]]; then
        run_test "Todas las categorías tienen ID" "jq -e '.categories[] | has(\"id\")' '$SCRIPT_DIR/packages.json'"
        run_test "Todas las categorías tienen emoji" "jq -e '.categories[] | has(\"emoji\")' '$SCRIPT_DIR/packages.json'"
        run_test "Todas las categorías tienen descripción" "jq -e '.categories[] | has(\"description\")' '$SCRIPT_DIR/packages.json'"
    fi
}

test_json_manager() {
    test_info "🔧 Probando json_manager.sh..."
    
    local json_manager="$SCRIPT_DIR/json_manager.sh"
    
    if [[ ! -f "$json_manager" ]]; then
        test_fail "json_manager.sh no encontrado"
        return 1
    fi
    
    run_test "json_manager.sh ejecuta sin errores" "bash '$json_manager' validate"
    run_test "json_manager.sh lista categorías" "bash '$json_manager' list-categories"
    run_test "json_manager.sh muestra estadísticas" "bash '$json_manager' stats"
    run_test "json_manager.sh muestra ayuda" "bash '$json_manager' help"
}

test_package_installer_dry_run() {
    test_info "📦 Probando package_installer.sh (modo seco)..."
    
    local installer="$SCRIPT_DIR/package_installer.sh"
    
    if [[ ! -f "$installer" ]]; then
        test_fail "package_installer.sh no encontrado"
        return 1
    fi
    
    # Verificar que el script tiene la estructura básica correcta
    run_test "Script contiene función main" "grep -q 'main()' '$installer'"
    run_test "Script contiene función show_banner" "grep -q 'show_banner()' '$installer'"
    run_test "Script contiene función check_dependencies" "grep -q 'check_dependencies()' '$installer'"
    run_test "Script contiene función install_package" "grep -q 'install_package()' '$installer'"
}

# ==============================================================================
# PRUEBAS DE DEPENDENCIAS Y SISTEMA
# ==============================================================================

test_system_dependencies() {
    test_info "🔍 Probando dependencias del sistema..."
    
    local required_commands=(
        "bash"
        "curl"
        "git"
    )
    
    for cmd in "${required_commands[@]}"; do
        run_test "Comando $cmd disponible" "command -v $cmd"
    done
    
    # Verificar dependencias opcionales
    local optional_commands=(
        "jq"
        "yay"
        "pacman"
    )
    
    for cmd in "${optional_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            test_pass "Comando opcional $cmd disponible"
        else
            test_info "Comando opcional $cmd no disponible (normal)"
        fi
    done
}

test_arch_linux_environment() {
    test_info "🐧 Probando entorno Arch Linux..."
    
    if [[ -f /etc/arch-release ]]; then
        test_pass "Sistema es Arch Linux"
        run_test "pacman disponible" "command -v pacman"
        
        # Verificar que pacman puede leer la base de datos
        run_test "Base de datos de pacman accesible" "pacman -Q > /dev/null"
    else
        test_skip "Sistema no es Arch Linux"
    fi
}

# ==============================================================================
# PRUEBAS DE INTEGRACIÓN
# ==============================================================================

test_json_package_consistency() {
    test_info "🔗 Probando consistencia JSON-Scripts..."
    
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq no disponible, omitiendo pruebas de consistencia"
        return 0
    fi
    
    # Verificar que no hay paquetes duplicados
    local duplicates
    duplicates=$(jq -r '[.categories[].packages[]?.name] | group_by(.) | map(select(length > 1)) | length' "$SCRIPT_DIR/packages.json")
    
    run_test "No hay paquetes duplicados" "[[ $duplicates -eq 0 ]]"
    
    # Verificar que todos los repositorios son válidos
    local invalid_repos
    invalid_repos=$(jq -r '[.categories[].packages[]? | select(.repo != "pacman" and .repo != "aur")] | length' "$SCRIPT_DIR/packages.json")
    
    run_test "Todos los repositorios son válidos" "[[ $invalid_repos -eq 0 ]]"
}

test_backup_functionality() {
    test_info "💾 Probando funcionalidad de backup..."
    
    local json_manager="$SCRIPT_DIR/json_manager.sh"
    local backup_dir="$SCRIPT_DIR/backups"
    
    if [[ -f "$json_manager" ]]; then
        # Crear backup
        if bash "$json_manager" backup >/dev/null 2>&1; then
            test_pass "Backup creado exitosamente"
            
            # Verificar que el backup existe
            if [[ -d "$backup_dir" ]] && [[ -n "$(find "$backup_dir" -name "packages_*.json" -type f)" ]]; then
                test_pass "Archivo de backup existe"
                
                # Limpiar backup de prueba
                rm -f "$backup_dir"/packages_*.json
            else
                test_fail "Archivo de backup no encontrado"
            fi
        else
            test_fail "Error al crear backup"
        fi
    else
        test_skip "json_manager.sh no disponible"
    fi
}

# ==============================================================================
# PRUEBAS DE RENDIMIENTO
# ==============================================================================

test_performance() {
    test_info "⚡ Probando rendimiento..."
    
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq no disponible, omitiendo pruebas de rendimiento"
        return 0
    fi
    
    # Medir tiempo de carga del JSON
    local start_time end_time duration
    start_time=$(date +%s%N)
    jq '.categories | length' "$SCRIPT_DIR/packages.json" >/dev/null
    end_time=$(date +%s%N)
    duration=$(( (end_time - start_time) / 1000000 )) # Convertir a milisegundos
    
    if [[ $duration -lt 1000 ]]; then
        test_pass "JSON se carga en menos de 1 segundo ($duration ms)"
    else
        test_fail "JSON tarda demasiado en cargar ($duration ms)"
    fi
}

# ==============================================================================
# REPORTE DE RESULTADOS
# ==============================================================================

show_test_summary() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                        📊 RESUMEN DE PRUEBAS                         ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo
    
    local success_rate=0
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        success_rate=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
    fi
    
    echo "📈 Estadísticas de Pruebas:"
    echo "   📊 Total de pruebas: $TESTS_TOTAL"
    echo "   ✅ Pruebas exitosas: $TESTS_PASSED"
    echo "   ❌ Pruebas fallidas: $TESTS_FAILED"
    echo "   📊 Tasa de éxito: $success_rate%"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "🎉 ¡Todas las pruebas pasaron exitosamente!"
        echo "✅ El sistema está listo para producción"
    elif [[ $success_rate -ge 80 ]]; then
        echo "⚠️  La mayoría de pruebas pasaron, pero hay algunos problemas menores"
        echo "🔧 Revisa los fallos en el log: $TEST_LOG"
    else
        echo "❌ Múltiples pruebas fallaron"
        echo "🚨 Se requiere revisión antes de usar en producción"
        echo "📄 Revisa el log completo: $TEST_LOG"
    fi
    
    echo
    echo "📄 Log completo de pruebas: $TEST_LOG"
}

create_test_report() {
    local report_file="$SCRIPT_DIR/test_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Dotfiles Testing Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 20px; border-radius: 5px; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        .skip { color: #ffc107; }
        .summary { background: #e9ecef; padding: 15px; margin: 20px 0; border-radius: 5px; }
        pre { background: #f8f9fa; padding: 10px; border-radius: 3px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🧪 Dotfiles Testing Report v2.0</h1>
        <p>Generado: $(date)</p>
        <p>Sistema: $(uname -a)</p>
    </div>
    
    <div class="summary">
        <h2>📊 Resumen</h2>
        <ul>
            <li>Total de pruebas: $TESTS_TOTAL</li>
            <li class="pass">Exitosas: $TESTS_PASSED</li>
            <li class="fail">Fallidas: $TESTS_FAILED</li>
            <li>Tasa de éxito: $(( TESTS_TOTAL > 0 ? TESTS_PASSED * 100 / TESTS_TOTAL : 0 ))%</li>
        </ul>
    </div>
    
    <h2>📄 Log Detallado</h2>
    <pre>$(cat "$TEST_LOG")</pre>
</body>
</html>
EOF
    
    test_info "📄 Reporte HTML generado: $report_file"
}

# ==============================================================================
# FUNCIÓN PRINCIPAL
# ==============================================================================

main() {
    local run_mode="${1:-all}"
    
    show_test_banner
    test_info "🚀 Iniciando suite de pruebas (modo: $run_mode)..."
    echo "📄 Log de pruebas: $TEST_LOG"
    echo
    
    case "$run_mode" in
        "structure"|"all")
            test_file_structure
            ;;
    esac
    
    case "$run_mode" in
        "json"|"all")
            test_json_validity
            test_json_manager
            ;;
    esac
    
    case "$run_mode" in
        "installer"|"all")
            test_package_installer_dry_run
            ;;
    esac
    
    case "$run_mode" in
        "system"|"all")
            test_system_dependencies
            test_arch_linux_environment
            ;;
    esac
    
    case "$run_mode" in
        "integration"|"all")
            test_json_package_consistency
            test_backup_functionality
            ;;
    esac
    
    case "$run_mode" in
        "performance"|"all")
            test_performance
            ;;
    esac
    
    show_test_summary
    create_test_report
    
    # Exit code basado en resultados
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Mostrar ayuda si se solicita
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    echo "🧪 Dotfiles Testing Suite v2.0"
    echo
    echo "USAGE: $0 [mode]"
    echo
    echo "MODES:"
    echo "  all          Ejecutar todas las pruebas (default)"
    echo "  structure    Probar estructura de archivos"
    echo "  json         Probar validez y gestión JSON"
    echo "  installer    Probar instalador de paquetes"
    echo "  system       Probar dependencias del sistema"
    echo "  integration  Probar integración entre componentes"
    echo "  performance  Probar rendimiento"
    echo
    echo "EXAMPLES:"
    echo "  $0           # Ejecutar todas las pruebas"
    echo "  $0 json      # Solo pruebas JSON"
    echo "  $0 system    # Solo pruebas del sistema"
    exit 0
fi

# Ejecutar si es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
