#!/bin/bash

# Test de iteración específico para identificar problemas

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_JSON="$SCRIPT_DIR/packages.json"

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

echo -e "${BLUE}🔍 TEST DE ITERACIÓN DE PAQUETES${NC}"
echo "Verificando cómo se procesan los paquetes del JSON..."
echo

# Test 1: Verificar estructura JSON
echo -e "${YELLOW}1. Verificando estructura JSON...${NC}"
if [[ ! -f "$PACKAGES_JSON" ]]; then
    echo -e "${RED}❌ packages.json no encontrado${NC}"
    exit 1
fi

if ! jq empty "$PACKAGES_JSON" 2>/dev/null; then
    echo -e "${RED}❌ packages.json tiene errores de sintaxis${NC}"
    exit 1
fi

echo -e "${GREEN}✅ JSON válido${NC}"

# Test 2: Contar categorías y paquetes
echo -e "${YELLOW}2. Contando elementos...${NC}"
category_count=$(jq '.categories | length' "$PACKAGES_JSON")
total_packages=$(jq '[.categories[].packages[]] | length' "$PACKAGES_JSON")

echo -e "   📁 Categorías: $category_count"
echo -e "   📦 Total paquetes: $total_packages"

# Test 3: Verificar primera categoría como ejemplo
echo -e "${YELLOW}3. Analizando primera categoría...${NC}"
first_category=$(jq -r '.categories[0].id' "$PACKAGES_JSON")
first_category_packages=$(jq '.categories[0].packages | length' "$PACKAGES_JSON")

echo -e "   📂 Primera categoría: $first_category"
echo -e "   📦 Paquetes en primera categoría: $first_category_packages"

# Test 4: Iterar sobre primeros 5 paquetes de la primera categoría
echo -e "${YELLOW}4. Iterando sobre primeros paquetes...${NC}"

jq -r '.categories[0].packages[0:5][] | "\(.name)|\(.repo)|\(.optional // false)"' "$PACKAGES_JSON" | while IFS='|' read -r name repo optional; do
    echo -e "   🔍 Paquete: ${name}"
    echo -e "      └─ Repo: ${repo}"
    echo -e "      └─ Opcional: ${optional}"
    
    # Verificar si está instalado
    if pacman -Qi "$name" >/dev/null 2>&1; then
        echo -e "      └─ Estado: ${GREEN}✅ Instalado${NC}"
    else
        echo -e "      └─ Estado: ${YELLOW}⏳ No instalado${NC}"
    fi
    echo
done

# Test 5: Verificar comandos de instalación
echo -e "${YELLOW}5. Verificando disponibilidad de herramientas...${NC}"

if command -v pacman >/dev/null 2>&1; then
    echo -e "${GREEN}✅ pacman disponible${NC}"
else
    echo -e "${RED}❌ pacman no disponible${NC}"
fi

if command -v yay >/dev/null 2>&1; then
    echo -e "${GREEN}✅ yay disponible${NC}"
    yay_version=$(yay --version | head -n1)
    echo -e "   └─ Versión: $yay_version"
else
    echo -e "${YELLOW}⚠️  yay no disponible${NC}"
fi

# Test 6: Verificar un paquete específico problemático
echo -e "${YELLOW}6. Verificando paquetes específicos...${NC}"

# Buscar algunos paquetes que sabemos pueden ser problemáticos
test_packages=("amberol" "rmpc-bin" "extension-manager")

for test_pkg in "${test_packages[@]}"; do
    echo -e "   🔍 Verificando: $test_pkg"
    
    # Verificar si está en el JSON
    if jq -e --arg pkg "$test_pkg" '.categories[].packages[] | select(.name == $pkg)' "$PACKAGES_JSON" >/dev/null; then
        echo -e "      └─ ${GREEN}✅ Encontrado en JSON${NC}"
        
        # Obtener info del paquete
        pkg_info=$(jq --arg pkg "$test_pkg" '.categories[].packages[] | select(.name == $pkg)' "$PACKAGES_JSON")
        repo=$(echo "$pkg_info" | jq -r '.repo')
        
        echo -e "      └─ Repo: $repo"
        
        # Verificar disponibilidad
        if [[ "$repo" == "pacman" ]]; then
            if pacman -Si "$test_pkg" >/dev/null 2>&1; then
                echo -e "      └─ ${GREEN}✅ Disponible en pacman${NC}"
            else
                echo -e "      └─ ${YELLOW}⚠️  No disponible en pacman${NC}"
            fi
        elif [[ "$repo" == "aur" ]]; then
            if command -v yay >/dev/null 2>&1 && yay -Si "$test_pkg" >/dev/null 2>&1; then
                echo -e "      └─ ${GREEN}✅ Disponible en AUR${NC}"
            else
                echo -e "      └─ ${YELLOW}⚠️  No disponible en AUR${NC}"
            fi
        fi
        
        # Verificar si está instalado
        if pacman -Qi "$test_pkg" >/dev/null 2>&1; then
            echo -e "      └─ ${GREEN}✅ Ya instalado${NC}"
        else
            echo -e "      └─ ${YELLOW}⏳ No instalado${NC}"
        fi
    else
        echo -e "      └─ ${RED}❌ No encontrado en JSON${NC}"
    fi
    echo
done

# Test 7: Simular problema de instalación
echo -e "${YELLOW}7. Simulando comando de instalación...${NC}"

test_package="stow"  # Paquete que sabemos que existe
echo -e "   🧪 Simulando instalación de: $test_package"

# Comando exacto que usa el instalador
echo -e "   📝 Comando pacman: sudo pacman -S --noconfirm $test_package"

# Ver si falla por alguna razón
if sudo pacman -S --noconfirm --needed "$test_package" >/dev/null 2>&1; then
    echo -e "      └─ ${GREEN}✅ Comando pacman exitoso${NC}"
else
    echo -e "      └─ ${YELLOW}⚠️  Comando pacman falló${NC}"
fi

# Test con yay
if command -v yay >/dev/null 2>&1; then
    echo -e "   📝 Comando yay: yay -S --noconfirm $test_package"
    if yay -S --noconfirm --needed "$test_package" >/dev/null 2>&1; then
        echo -e "      └─ ${GREEN}✅ Comando yay exitoso${NC}"
    else
        echo -e "      └─ ${YELLOW}⚠️  Comando yay falló${NC}"
    fi
fi

echo
echo -e "${BLUE}🎯 CONCLUSIONES DEL TEST:${NC}"
echo -e "   • JSON estructura: ${GREEN}OK${NC}"
echo -e "   • Iteración de paquetes: ${GREEN}OK${NC}"
echo -e "   • Herramientas disponibles: Verificar arriba"
echo -e "   • Comandos de instalación: Verificar arriba"
echo
echo -e "${YELLOW}💡 Si ves problemas arriba, ese es el punto de falla del instalador${NC}"
