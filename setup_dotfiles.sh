#!/bin/bash

# Función para mostrar un banner bonito
show_banner() {
    echo -e "\e[1;34m"
    echo "                    ___           ___     "
    echo "     _____         /\  \         /\__\    "
    echo "    /::\  \       /::\  \       /:/ _/_   "
    echo "   /:/\:\  \     /::::\  \     /:/ /\__\  "
    echo "  /:/  \:\__\   /::::::\  \   /:/ /:/  /  "
    echo " /:/__/ \:|__| /:::LS:::\__\ /:/_/:/  /   "
    echo " \:\  \ /:/  / \::1994::/  / \:\/:/  /    "
    echo "  \:\  /:/  /   \::::::/  /   \::/__/     "
    echo "   \:\/:/  /     \::::/  /     \:\  \     "
    echo "    \::/  /       \::/  /       \:\__\    "
    echo "     \/__/         \/__/         \/__/    "
    echo -e "\e[0m"
}

# Función para mostrar un título de sección
show_section() {
    local section=$1
    echo -e "\e[1;32m"
    echo "-------------------------------------------"
    echo " $section"
    echo "-------------------------------------------"
    echo -e "\e[0m"
}

# Función para mostrar un mensaje de información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Función para hacer backup de archivos o directorios existentes, excepto enlaces simbólicos
backup_file() {
    local file=$1
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        show_info "El archivo o directorio $file ya existe y no es un enlace simbólico. Creando backup..."
        mv "$file" "$file.backup_$(date +%F_%T)"
        show_info "Backup creado: $file.backup_$(date +%F_%T)"
        BACKUP_FILES+=("$file.backup_$(date +%F_%T)")
    fi
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
NEW_LINKS=()
BACKUP_FILES=()
SKIPPED_LINKS=()

# Instalación de stow si no está instalado
if ! command -v stow &> /dev/null; then
    show_info "stow no está instalado. Instalando stow..."
    sudo pacman -Sy stow --noconfirm
else
    show_info "stow ya está instalado."
fi

# Directorio de dotfiles
DOTFILES_DIR=$(pwd)

# Archivos y carpetas a configurar
declare -A DOTFILES

# Función para añadir un archivo de configuración
add_dotfile() {
    local name=$1
    local path=$2
    DOTFILES["$name"]="$path"
}

# Añadir configuraciones existentes
add_dotfile "zsh" ".zshrc"
add_dotfile "ranger" ".config/ranger"
add_dotfile "tmux" ".config/tmux"
add_dotfile "starship" ".config/starship.toml"
add_dotfile "zathura" ".config/zathura"
# ---- AÑADIR NUEVO ARCHIVO CON LA FUNCION ----

# Crear backups de archivos o directorios existentes, excepto enlaces simbólicos
show_section "Creando backups si es necesario"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    backup_file "$target"
done

# Aplicar configuraciones con stow
show_section "Aplicando configuraciones con stow"
for key in "${!DOTFILES[@]}"; do
    target="${HOME}/${DOTFILES[$key]}"
    if [ -L "$target" ]; then
        show_info "Enlace simbólico para $key ya existe en $target. Omitiendo..."
        SKIPPED_LINKS+=("$target")
    else
        show_info "Aplicando configuración para $key..."
        stow -v "$key"
        if [ $? -eq 0 ]; then
            show_info "Configuración para $key aplicada con éxito."
            NEW_LINKS+=("$target")
        else
            show_info "Error al aplicar la configuración para $key."
        fi
    fi
done

# Instalar Starship sin pedir confirmación
show_section "Instalando Starship"
show_info "Instalando Starship..."
curl -sS https://starship.rs/install.sh | sh -s -- --yes

# Instalar tmux plugin manager (tpm)
show_section "Instalando tmux plugin manager (tpm)"
show_info "Instalando tmux plugin manager (tpm)..."
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Resumen
show_section "Resumen de la instalación"
echo "Enlaces nuevos creados y ubicaciones:"
for link in "${NEW_LINKS[@]}"; do
    echo " - $link"
done

echo "---------------------------"
echo "Archivos o carpetas ya existentes que fueron respaldados:"
for backup in "${BACKUP_FILES[@]}"; do
    echo " - $backup"
done

echo "---------------------------"
echo "Enlaces ya existentes que fueron omitidos:"
for skipped in "${SKIPPED_LINKS[@]}"; do
    echo " - $skipped"
done

# Mensajes de información adicionales
show_section "Información adicional"
show_info "Instalación y configuración completadas."
show_info "Por favor, reinicie la terminal para aplicar los cambios."
show_info "Para tmux, borre todo en la carpeta plugins y use el comando Ctrl + Space + I para reinstalar los plugins."

