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
declare -a CORRECT_LINKS

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
# Ejemplos:
#  Archivo específico: add_dotfile "mi_zsh" "zsh/.zshrc" "$HOME/.zshrc"
#  Carpeta completa:   add_dotfile "mi_ranger" "ranger/.config/ranger" "$HOME/.config/ranger"

# Archivos específicos
add_dotfile "zsh"      "zsh/.zshrc"                                  "$HOME/.zshrc"
add_dotfile "tmux"     "tmux/.config/tmux/tmux.conf"                "$HOME/.config/tmux/tmux.conf"    # Archivo específico
add_dotfile "starship" "starship/.config/starship.toml"              "$HOME/.config/starship.toml"
add_dotfile "nvim_init" "nvim/.config/nvim/init.lua"               "$HOME/.config/nvim/init.lua"     # Archivo específico
add_dotfile "git"      "git/.gitconfig"                             "$HOME/.gitconfig"
add_dotfile "kitty"    "kitty/.config/kitty/kitty.conf"             "$HOME/.config/kitty/kitty.conf"  # Archivo específico
add_dotfile "mpd"      "mpd/.config/mpd/mpd.conf"                   "$HOME/.config/mpd/mpd.conf"      # Archivo específico

# Carpetas completas
add_dotfile "ranger"       "ranger/.config/ranger"                  "$HOME/.config/ranger"            # Carpeta completa
add_dotfile "zathura"      "zathura/.config/zathura"               "$HOME/.config/zathura"           # Carpeta completa
add_dotfile "nvim_custom"  "nvim/.config/nvim/lua/custom"          "$HOME/.config/nvim/lua/custom"   # Carpeta completa

# Opciones de ejecución (menú interactivo)
print_usage() {
    echo "Uso: $0"
    echo "  1) Aplicar enlaces preguntando uno a uno (por defecto)"
    echo "  2) Estado general de los enlaces (OK, faltantes o mal dirigidos)"
    echo "  3) Dry-run: mostrar qué enlaces se crearían sin aplicar cambios"
    echo "  4) Ayuda"
}

# Seleccionar modo al inicio
show_section "Seleccione una opción:"
echo "1) Aplicar enlaces preguntando uno a uno (por defecto)"
echo "2) Estado general de los enlaces (OK, faltantes o mal dirigidos)"
echo "3) Dry-run: mostrar qué enlaces se crearían sin aplicar cambios"
echo "4) Ayuda"
read -p "Opción [1]: " option
case "$option" in
    ""|1) mode="apply" ;;  
    2) mode="status" ;;  
    3) mode="dryrun" ;;  
    4) print_usage; exit 0 ;;  
    *) echo "Opción inválida"; exit 1 ;;  
esac

# Estado general de enlaces
status_dotfiles_links() {
    show_section "Estado general de los enlaces"
    for key in "${!DOTFILES[@]}"; do
        IFS=':' read -r rel_src dest <<< "${DOTFILES[$key]}"
        src="$DOTFILES_DIR/$rel_src"
        if [ -L "$dest" ]; then
            tgt=$(readlink "$dest")
            if [ "$tgt" = "$src" ]; then
                printf "[32m[✓][0m %-12s %s -> %s\n" "$key" "$dest" "$src"
            else
                printf "[33m[!][0m %-12s %s -> %s (esperado: %s)\n" "$key" "$dest" "$tgt" "$src"
            fi
        else
            printf "[31m[✗][0m %-12s %s (origen: %s)\n" "$key" "$dest" "$src"
        fi
    done
    # Leyenda de símbolos
    echo
    show_section "Leyenda de símbolos"
    echo -e "\e[32m[✓]\e[0m Enlace existente y correcto (destino apunta al origen esperado)"
    echo -e "\e[33m[!]\e[0m Enlace existente pero desviado (apunta a otro lugar distinto al esperado)"
    echo -e "\e[31m[✗]\e[0m Enlace faltante (no existe enlace en destino)"
}

# Dry-run: qué enlaces se crearían
dryrun_dotfiles_links() {
    show_section "Dry-run: enlaces a crear"
    for key in "${!DOTFILES[@]}"; do
        IFS=':' read -r src dest <<< "${DOTFILES[$key]}"
        src="$DOTFILES_DIR/$src"
        if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
            show_info "Ya existe: $dest -> $src"
        else
            show_info "Se crearía: $dest -> $src"
        fi
    done
}

# Función para verificar enlaces existentes sin crear nuevos
verify_dotfiles_links() {
    show_section "Verificando enlaces existentes"
    for key in "${!DOTFILES[@]}"; do
        IFS=':' read -r src dest <<< "${DOTFILES[$key]}"
        src="$DOTFILES_DIR/$src"
        if [ -L "$dest" ]; then
            tgt=$(readlink "$dest")
            if [ "$tgt" = "$src" ]; then
                show_info "OK: $dest -> $tgt"
            else
                show_info "Desviado: $dest apunta a $tgt (esperado -> $src)"
            fi
        else
            show_info "No es enlace: $dest"
        fi
    done
}

# Ejecutar según modo seleccionado
case "$mode" in
    status)  status_dotfiles_links; exit 0 ;;  
    dryrun) dryrun_dotfiles_links; exit 0 ;;  
    apply)  ;;  # continúa hacia create_symlink
esac

# Crear enlaces para cada configuración
show_section "Verificando y creando enlaces simbólicos para archivos de configuración"
for key in "${!DOTFILES[@]}"; do
    IFS=':' read -r rel_src target_path <<< "${DOTFILES[$key]}"
    source_path="$DOTFILES_DIR/$rel_src"
    # Si el enlace ya existe y apunta correctamente, omitir sin prompt
    if [ -L "$target_path" ] && [ "$(readlink "$target_path")" = "$source_path" ]; then
        # Mostrar símbolo ✓ con nombre y rutas
        printf "\e[32m[✓]\e[0m %-12s %s -> %s\n" "$key" "$target_path" "$source_path"
        CORRECT_LINKS+=("$target_path")
        continue
    fi
    # Confirmar y crear nuevo enlace para los que faltan o estén mal dirigidos
    confirm_dotfile "$key" "$source_path" "$target_path"
    if [ $? -eq 0 ]; then
        create_symlink "$source_path" "$target_path"
    else
        show_info "Omitiendo la configuración de $key"
    fi
done

# Resumen
show_section "Resumen de la ejecución"
echo "1) Nuevos enlaces creados:"
if [ ${#NEW_LINKS[@]} -gt 0 ]; then
    for link in "${NEW_LINKS[@]}"; do
        echo "   - $link"
    done
else
    show_info "   Ninguno: todas las configuraciones ya estaban aplicadas o correctamente existentes"
fi

echo "---------------------------"
echo "2) Backups realizados:"
if [ ${#BACKUP_FILES[@]} -gt 0 ]; then
    for backup in "${BACKUP_FILES[@]}"; do
        echo "   - $backup"
    done
else
    show_info "   Ninguno: no se requirió backup"
fi

echo "---------------------------"
echo "3) Enlaces omitidos por usuario:"
if [ ${#SKIPPED_LINKS[@]} -gt 0 ]; then
    for skipped in "${SKIPPED_LINKS[@]}"; do
        echo "   - $skipped"
    done
else
    show_info "   Ninguno: no se omitió ninguna configuración manualmente"
fi

echo "---------------------------"
echo "4) Enlaces ya existentes y correctos:"
if [ ${#CORRECT_LINKS[@]} -gt 0 ]; then
    for correct in "${CORRECT_LINKS[@]}"; do
        echo "   - $correct"
    done
else
    show_info "   Ninguno: no se detectaron enlaces preexistentes"
fi

# Mensajes de información adicionales
show_section "Información adicional"
show_info "Instalación y configuración completadas. Recuerda:"
show_info "- Después de aplicar los enlaces, abre tmux y usa Ctrl + Space + Shift + I para instalar los plugins descritos en el archivo tmux.conf."
show_info "- Abre Neovim para verificar que las configuraciones personalizadas y plugins se han cargado correctamente."
show_info "- Reinicia la terminal para aplicar los cambios en Starship."

