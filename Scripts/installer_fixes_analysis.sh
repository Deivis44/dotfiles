#!/bin/bash

# ==============================================================================
# INSTALADOR CORREGIDO - ANÁLISIS DE PROBLEMAS ENCONTRADOS
# ==============================================================================

# PROBLEMAS IDENTIFICADOS EN EL INSTALADOR ORIGINAL:
# 1. Manejo de errores insuficiente en pacman/yay
# 2. No usa --needed flag que evita reinstalaciones
# 3. Falta de reintentos en caso de fallos temporales
# 4. Output de errores puede no ser visible
# 5. No verifica disponibilidad de paquetes antes de intentar instalar
# 6. Manejo de casos edge con nombres de paquetes problemáticos

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                          ANÁLISIS DE PROBLEMAS                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

🔍 PROBLEMAS IDENTIFICADOS EN LA FUNCIÓN install_package():

1. ❌ REDIRECCIÓN DE ERRORES AGRESIVA
   - Problema: 2>/dev/null oculta errores importantes
   - Efecto: No vemos por qué fallan las instalaciones
   - Solución: Capturar y mostrar errores relevantes

2. ❌ FALTA DE FLAG --needed
   - Problema: Intenta reinstalar paquetes ya instalados
   - Efecto: Operaciones innecesarias y posibles conflictos
   - Solución: Usar --needed flag

3. ❌ NO HAY REINTENTOS
   - Problema: Un fallo temporal termina la instalación
   - Efecto: Instalaciones fallidas por problemas de red
   - Solución: Implementar sistema de reintentos

4. ❌ NO VERIFICA DISPONIBILIDAD
   - Problema: No verifica si el paquete existe antes de intentar
   - Efecto: Fallos innecesarios y confusión
   - Solución: Verificar disponibilidad primero

5. ❌ MANEJO DE NOMBRES PROBLEMÁTICOS
   - Problema: Algunos nombres de paquetes pueden tener caracteres especiales
   - Efecto: Fallos inesperados en parsing
   - Solución: Escapar nombres correctamente

6. ❌ ORDEN DE INSTALACIÓN
   - Problema: No considera dependencias entre paquetes
   - Efecto: Fallos por dependencias no resueltas
   - Solución: Instalar dependencias primero

MEJORES PRÁCTICAS DE YAY Y PACMAN:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Usar flags correctos:
   pacman -S --needed --noconfirm PACKAGE
   yay -S --needed --noconfirm PACKAGE

✅ Verificar disponibilidad:
   pacman -Si PACKAGE (repositorios oficiales)
   yay -Si PACKAGE (AUR)

✅ Capturar errores útiles:
   No usar 2>/dev/null, sino capturar stdout/stderr

✅ Verificar códigos de salida:
   Usar $? para verificar éxito real

✅ Timeout para operaciones:
   Evitar bloqueos indefinidos

EOF

echo
echo "🔧 GENERANDO FUNCIÓN CORREGIDA..."
echo

# ==============================================================================
# FUNCIÓN CORREGIDA ROBUSTA
# ==============================================================================

cat << 'EOF'
install_package_robust() {
    local package="$1"
    local repo="$2"
    local optional="$3"
    local category="$4"
    local install_mode="$5"
    
    # Validar entrada
    if [[ -z "$package" ]]; then
        error "Nombre de paquete vacío"
        return 1
    fi
    
    # Escapar caracteres especiales en nombre de paquete
    local safe_package
    safe_package=$(printf '%q' "$package")
    
    # Verificar si ya está instalado (más robusto)
    if pacman -Qq "$package" >/dev/null 2>&1; then
        info "📦 $package ya está instalado (pacman)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar con yay para paquetes AUR instalados
    if command -v yay >/dev/null 2>&1 && yay -Qq "$package" >/dev/null 2>&1; then
        info "📦 $package ya está instalado (yay)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Verificar modo de instalación para paquetes opcionales
    if [[ "$optional" == "true" ]] && [[ "$install_mode" == "required_only" ]]; then
        info "⏭️  Omitiendo $package (paquete opcional en modo required_only)"
        ((TOTAL_SKIPPED++))
        return 0
    fi
    
    # Preguntar al usuario en modo selectivo
    if [[ "$install_mode" == "selective" ]]; then
        if ! ask_yes_no "¿Instalar $package ($repo)?"; then
            info "⏭️  Usuario omitió $package"
            ((TOTAL_SKIPPED++))
            return 0
        fi
    fi
    
    # Verificar disponibilidad antes de intentar instalar
    local available=false
    if [[ "$repo" == "pacman" ]]; then
        if pacman -Si "$package" >/dev/null 2>&1; then
            available=true
        fi
    elif [[ "$repo" == "aur" ]]; then
        if command -v yay >/dev/null 2>&1; then
            if yay -Si "$package" >/dev/null 2>&1; then
                available=true
            fi
        else
            error "yay no está disponible para paquetes AUR"
            ((TOTAL_FAILED++))
            return 1
        fi
    fi
    
    if [[ "$available" != "true" ]]; then
        error "❌ Paquete $package no está disponible en $repo"
        ((TOTAL_FAILED++))
        return 1
    fi
    
    info "🔄 Instalando $package desde $repo..."
    
    # Sistema de reintentos robusto
    local max_retries=3
    local retry_delay=2
    local success=false
    local last_error=""
    
    for ((attempt=1; attempt<=max_retries; attempt++)); do
        if [[ $attempt -gt 1 ]]; then
            warning "Intento $attempt/$max_retries para $package"
            sleep $retry_delay
        fi
        
        local install_output
        local install_result
        
        if [[ "$repo" == "pacman" ]]; then
            # Intentar con pacman primero
            install_output=$(sudo pacman -S --needed --noconfirm "$package" 2>&1)
            install_result=$?
            
            if [[ $install_result -eq 0 ]]; then
                success=true
                break
            else
                last_error="$install_output"
                
                # Si pacman falla, intentar con yay (puede estar en AUR)
                if command -v yay >/dev/null 2>&1; then
                    info "   Pacman falló, intentando con yay..."
                    install_output=$(yay -S --needed --noconfirm "$package" 2>&1)
                    install_result=$?
                    
                    if [[ $install_result -eq 0 ]]; then
                        success=true
                        break
                    else
                        last_error="$install_output"
                    fi
                fi
            fi
            
        elif [[ "$repo" == "aur" ]]; then
            # Para paquetes AUR, usar yay directamente
            if command -v yay >/dev/null 2>&1; then
                install_output=$(yay -S --needed --noconfirm "$package" 2>&1)
                install_result=$?
                
                if [[ $install_result -eq 0 ]]; then
                    success=true
                    break
                else
                    last_error="$install_output"
                fi
            else
                error "yay no está disponible para paquetes AUR"
                ((TOTAL_FAILED++))
                return 1
            fi
        fi
        
        # Si llegamos aquí, el intento falló
        if [[ $attempt -lt $max_retries ]]; then
            warning "Intento $attempt falló: $(echo "$last_error" | head -n1)"
        fi
    done
    
    if [[ "$success" == "true" ]]; then
        success "✅ $package instalado correctamente"
        ((TOTAL_INSTALLED++))
        return 0
    else
        error "❌ Error al instalar $package después de $max_retries intentos"
        error "   Último error: $(echo "$last_error" | head -n2 | tr '\n' ' ')"
        ((TOTAL_FAILED++))
        return 1
    fi
}
EOF

echo
echo "📋 FUNCIÓN CORREGIDA GENERADA"
echo
echo "🔧 DIFERENCIAS PRINCIPALES:"
echo "   ✅ Verificación robusta de paquetes instalados"
echo "   ✅ Validación de disponibilidad antes de instalar"
echo "   ✅ Sistema de reintentos con delay"
echo "   ✅ Captura y muestra de errores específicos"
echo "   ✅ Uso de --needed flag"
echo "   ✅ Escape de caracteres especiales"
echo "   ✅ Mejor logging y feedback"
echo
echo "🎯 PRÓXIMOS PASOS:"
echo "   1. Probar el script de depuración primero"
echo "   2. Identificar paquetes problemáticos específicos"
echo "   3. Aplicar correcciones al instalador principal"
echo
