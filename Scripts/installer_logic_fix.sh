#!/bin/bash

# ==============================================================================
# INSTALADOR CORREGIDO - LÓGICA INTELIGENTE
# ==============================================================================

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}🔧 ANALIZANDO EL PROBLEMA DEL INSTALADOR${NC}"
echo

# ==============================================================================
# PROBLEMA IDENTIFICADO
# ==============================================================================

cat << 'EOF'
🎯 PROBLEMA PRINCIPAL IDENTIFICADO:

❌ LÓGICA INCORRECTA ACTUAL:
   - El instalador confía ciegamente en el campo "repo" del JSON
   - Si dice "repo": "pacman" → solo intenta pacman
   - Si dice "repo": "aur" → solo intenta yay
   - Si pacman falla, NO intenta yay automáticamente

✅ LÓGICA CORRECTA QUE NECESITAMOS:
   - El campo "repo" es SOLO informativo/visual
   - SIEMPRE intentar pacman primero (repositorios oficiales)
   - SI pacman falla → intentar yay (AUR)
   - NO importa lo que diga el JSON

📋 EJEMPLO DEL PROBLEMA:
   - "amberol" está marcado como "repo": "aur" en el JSON
   - Pero amberol ESTÁ en repositorios oficiales (extra)
   - El instalador solo intenta yay y puede fallar

EOF

echo
echo -e "${YELLOW}🔍 Verificando casos problemáticos...${NC}"

# Casos de prueba
test_packages=("amberol" "stow" "git" "rmpc-bin" "extension-manager")

for pkg in "${test_packages[@]}"; do
    echo -e "\n📦 Analizando: ${BLUE}$pkg${NC}"
    
    # Obtener info del JSON
    if jq -e --arg pkg "$pkg" '.categories[].packages[] | select(.name == $pkg)' "$PACKAGES_JSON" >/dev/null 2>&1; then
        json_repo=$(jq -r --arg pkg "$pkg" '.categories[].packages[] | select(.name == $pkg) | .repo' "$PACKAGES_JSON")
        echo -e "   📋 JSON dice: repo = '$json_repo'"
        
        # Verificar en pacman (repositorios oficiales)
        if pacman -Si "$pkg" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Disponible en pacman (repositorios oficiales)${NC}"
        else
            echo -e "   ${RED}❌ NO disponible en pacman${NC}"
        fi
        
        # Verificar en yay/AUR
        if command -v yay >/dev/null 2>&1 && yay -Si "$pkg" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Disponible en yay/AUR${NC}"
        else
            echo -e "   ${RED}❌ NO disponible en yay/AUR${NC}"
        fi
        
        # Verificar si está instalado
        if pacman -Qi "$pkg" >/dev/null 2>&1; then
            echo -e "   ${GREEN}✅ Ya está instalado${NC}"
        else
            echo -e "   ${YELLOW}⏳ No está instalado${NC}"
        fi
    else
        echo -e "   ${RED}❌ No encontrado en JSON${NC}"
    fi
done

echo
echo -e "${BLUE}🛠️ FUNCIÓN CORREGIDA:${NC}"

cat << 'EOF'

install_package_intelligent() {
    local package="$1"
    local repo_hint="$2"      # Solo informativo, NO determinante
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Verificar si ya está instalado
    if pacman -Qi "$package" >/dev/null 2>&1; then
        info "📦 $package ya está instalado"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "⏭️  Omitiendo $package (paquete opcional)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        if ! ask_yes_no "¿Instalar $package?"; then
            info "⏭️  Usuario omitió $package"
            ((TOTAL_SKIPPED++))
            return 0
        fi
    fi
    
    info "🔄 Instalando $package (hint: $repo_hint)..."
    
    # ============================================================================
    # LÓGICA INTELIGENTE: SIEMPRE PROBAR PACMAN PRIMERO, LUEGO YAY
    # ============================================================================
    
    local success=false
    local install_method=""
    local error_log=""
    
    # PASO 1: Intentar con pacman (repositorios oficiales)
    info "   🔍 Intentando con pacman..."
    if sudo pacman -S --needed --noconfirm "$package" 2>/dev/null; then
        success=true
        install_method="pacman (repositorios oficiales)"
    else
        error_log="Pacman falló"
        
        # PASO 2: Si pacman falla, intentar con yay (AUR)
        if command -v yay >/dev/null 2>&1; then
            info "   🔍 Pacman falló, intentando con yay..."
            if yay -S --needed --noconfirm "$package" 2>/dev/null; then
                success=true
                install_method="yay (AUR)"
            else
                error_log="$error_log; yay también falló"
            fi
        else
            error_log="$error_log; yay no disponible"
        fi
    fi
    
    if [[ "$success" == "true" ]]; then
        success "✅ $package instalado correctamente con $install_method"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "❌ Error al instalar $package: $error_log"
        ((TOTAL_FAILED++))
        return 1
    fi
}

EOF

echo
echo -e "${GREEN}🎯 RESUMEN DE LA CORRECCIÓN:${NC}"
echo
echo -e "   ✅ El campo 'repo' del JSON es solo informativo"
echo -e "   ✅ SIEMPRE intentar pacman primero"
echo -e "   ✅ Si pacman falla → intentar yay automáticamente"
echo -e "   ✅ Usar flag --needed para evitar reinstalaciones"
echo -e "   ✅ Mejor logging de qué método funcionó"
echo
echo -e "${YELLOW}📝 PRÓXIMO PASO:${NC}"
echo -e "   Aplicar esta corrección al full_installer_v2.sh"
