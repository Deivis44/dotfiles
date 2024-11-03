#!/bin/bash

# Variables de ruta
DOTFILES_DIR="$HOME/dotfiles"
SCRIPTS_DIR="$DOTFILES_DIR/Scripts"
ADDITIONAL_DIR="$SCRIPTS_DIR/Additional"
LOG_FILE="$HOME/Downloads/resumen_instalacion.txt"

# Función para mostrar un título de sección
show_section() {
    local section=$1
    echo -e "\e[1;32m-------------------------------------------"
    echo " $section"
    echo -e "-------------------------------------------\e[0m"
}

# Función para mostrar información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Crear el archivo de resumen con encabezado
echo "Resumen de la instalación - $(date)" > "$LOG_FILE"
show_info "Log de instalación guardado en: $LOG_FILE"

# Asegurar que todos los scripts tengan permisos de ejecución
chmod +x "$SCRIPTS_DIR"/*.sh
chmod +x "$ADDITIONAL_DIR"/*.sh

# 1. Instalar Hyprland personalizado (opcional)
read -p "¿Deseas instalar la configuración personalizada de Hyprland de end-4? (s/n): " install_hyprland
if [[ $install_hyprland =~ ^[Ss]$ ]]; then
    show_section "Instalando configuración de Hyprland de end-4"
    bash <(curl -s "https://end-4.github.io/dots-hyprland-wiki/setup.sh") | tee -a "$LOG_FILE"
    show_info "Configuración de Hyprland instalada."
else
    show_info "Configuración de Hyprland omitida."
fi

# 2. Ejecutar el script de instalación de paquetes principales
read -p "¿Deseas ejecutar el script de instalación principal de paquetes? (s/n): " install_main_packages
if [[ $install_main_packages =~ ^[Ss]$ ]]; then
    show_section "Ejecutando install-packages.sh"
    "$SCRIPTS_DIR/install-packages.sh" | tee -a "$LOG_FILE"
    show_info "install-packages.sh completado."
else
    show_info "install-packages.sh omitido."
fi

# 3. Ejecutar el script de instalación de paquetes adicionales
read -p "¿Deseas ejecutar el script de instalación de paquetes adicionales? (s/n): " install_additional_packages
if [[ $install_additional_packages =~ ^[Ss]$ ]]; then
    show_section "Ejecutando install_extra_packs.sh"
    "$SCRIPTS_DIR/install_extra_packs.sh" | tee -a "$LOG_FILE"
    show_info "install_extra_packs.sh completado."
else
    show_info "install_extra_packs.sh omitido."
fi

# 4. Preguntar si quiere ejecutar el script stow-links.sh
read -p "¿Quieres ejecutar el script de stow-links.sh ahora? (s/n): " ejecutar_stow
if [[ $ejecutar_stow =~ ^[Ss]$ ]]; then
    show_section "Ejecutando stow-links.sh"
    "$SCRIPTS_DIR/stow-links.sh" | tee -a "$LOG_FILE"
    show_info "stow-links.sh completado."
else
    show_info "stow-links.sh omitido."
fi

# 5. Ejecutar scripts adicionales de la carpeta Additional
show_section "Scripts adicionales"

# Listar los scripts en la carpeta Additional y preguntar uno por uno
additional_scripts=("$ADDITIONAL_DIR"/*.sh)
for script in "${additional_scripts[@]}"; do
    script_name=$(basename "$script")
    read -p "¿Quieres ejecutar $script_name? (s/n): " ejecutar_script
    if [[ $ejecutar_script =~ ^[Ss]$ ]]; then
        show_section "Ejecutando $script_name"
        bash "$script" | tee -a "$LOG_FILE"
        show_info "$script_name completado."
    else
        show_info "$script_name omitido."
    fi
done

# Resumen final
show_section "Resumen Final de la Instalación"
cat "$LOG_FILE"

show_info "Proceso de instalación finalizado. Revisa el archivo de log en $LOG_FILE para más detalles sobre los mensajes de ayuda."

