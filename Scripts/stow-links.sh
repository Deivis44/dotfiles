#!/bin/bash

# Ruta base para los dotfiles en Config dentro del repositorio de dotfiles
DOTFILES_DIR="$HOME/dotfiles/Config"

# Función para mostrar un banner bonito
show_banner() {
    echo -e "\e[1;34m"
    echo "                    ___           ___     "
    echo "     _____         /\  \         /\__\    "
    echo "    /::\  \       /::\  \       /:/ _/_   "
    echo "   /:/\:\  \     /::::\  \     /:/ /\__\  "
    echo "  /:/  \:\__\   /::::::\  \   /:/ /:/  /  "
    echo " /:/__/ \:|__| /:::DM:::\__\ /:/_/:/  /   "
    echo " \:\  \ /:/  / \::2004::/  / \:\/:/  /    "
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
        local backup_name="$file.backup_$(date +%F_%T)"
        mv "$file" "$backup_name"
        show_info "Backup creado: $backup_name"
        BACKUP_FILES+=("$backup_name")
    fi
}

# Función para verificar y confirmar el destino de cada dotfile
confirm_dotfile() {
    local name=$1
    local source_path=$2
    local target_path=$3
    
    echo "Configuración: $name"
    echo "   Archivo fuente: $source_path"
    echo "   Ubicación destino: $target_path"

    # Confirmar con el usuario si desea continuar
    read -p "¿Desea continuar con esta configuración? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        SKIPPED_LINKS+=("$target_path")
        return 1
    fi
    
    # Crear el directorio destino si no existe
    local target_dir
    target_dir=$(dirname "$target_path")
    if [ ! -d "$target_dir" ]; then
        show_info "Creando directorio $target_dir..."
        mkdir -p "$target_dir"
    fi

    return 0
}

# Función para crear enlaces simbólicos
create_symlink() {
    local source_path="$1"
    local target_path="$2"

    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_file "$target_path"
        rm -rf "$target_path"
    fi

    ln -s "$source_path" "$target_path"
    show_info "Enlace simbólico creado desde $source_path hacia $target_path"
    NEW_LINKS+=("$target_path")
}

# Mostrar banner
show_banner

# Inicializar arrays para el resumen
declare -a NEW_LINKS
declare -a BACKUP_FILES
declare -a SKIPPED_LINKS

# Declarar array asociativo para dotfiles
declare -A DOTFILES

# Añadir configuraciones específicas (archivos individuales o carpetas completas)
add_dotfile() {
    local name=$1
    local source=$2
    local destination=$3
    DOTFILES["$name"]="$source:$destination"
}

# Añadir configuraciones
# Sintaxis: add_dotfile "nombre" "ruta_en_Config" "ruta_en_destino"
add_dotfile "zsh" "zsh/.zshrc" "$HOME/.zshrc"
add_dotfile "ranger" "ranger/.config/ranger" "$HOME/.config/ranger"       # Carpeta completa
add_dotfile "tmux" "tmux/.config/tmux/tmux.conf" "$HOME/.config/tmux/tmux.conf" # Archivo específico
add_dotfile "starship" "starship/.config/starship.toml" "$HOME/.config/starship.toml"
add_dotfile "zathura" "zathura/.config/zathura" "$HOME/.config/zathura"   # Carpeta completa
add_dotfile "nvim_custom" "nvim/.config/nvim/lua/custom" "$HOME/.config/nvim/lua/custom" # Carpeta específica
add_dotfile "nvim_init" "nvim/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua" # Archivo específico
add_dotfile "git" "git/.gitconfig" "$HOME/.gitconfig"
add_dotfile "kitty" "kitty/.config/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" # Archivo específico

# Crear enlaces simbólicos para cada configuración
show_section "Verificando y creando enlaces simbólicos para archivos de configuración"
for key in "${!DOTFILES[@]}"; do
    IFS=':' read -r source_path target_path <<< "${DOTFILES[$key]}"
    source_path="$DOTFILES_DIR/$source_path"
    
    # Confirmar la configuración antes de crear el enlace simbólico
    confirm_dotfile "$key" "$source_path" "$target_path"
    if [ $? -eq 0 ]; then
        create_symlink "$source_path" "$target_path"
    else
        show_info "Omitiendo la configuración de $key"
    fi
done

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
show_info "Instalación y configuración completadas. Recuerda:"
show_info "- Después de aplicar los enlaces, abre tmux y usa Ctrl + Space + Shift + I para instalar los plugins descritos en el archivo tmux.conf."
show_info "- Abre Neovim para verificar que las configuraciones personalizadas y plugins se han cargado correctamente."
show_info "- Reinicia la terminal para aplicar los cambios en Starship."

