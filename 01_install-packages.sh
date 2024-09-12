#!/bin/bash

# Función para mostrar un mensaje de información
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

# Función para mostrar un mensaje de error
show_error() {
    local message=$1
    echo -e "\e[1;31m$message\e[0m"
}

# Función para mostrar un mensaje de éxito
show_success() {
    local message=$1
    echo -e "\e[1;32m$message\e[0m"
}

# Función para preguntar si se desea instalar un paquete
ask_install() {
    local pkg=$1
    while true; do
        read -p "¿Quieres instalar $pkg? [s/n]: " yn
        case $yn in
            [Ss]* ) return 0;;  # Sí
            [Nn]* ) return 1;;  # No
            * ) echo "Por favor, responde con s/n.";;
        esac
    done
}

# Opción 1: dots-hyprland version (tu enfoque con yay-bin)
install_yay_dots_hyprland() {
    show_info "Instalando yay (dots-hyprland version)..."
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay-bin.git /tmp/buildyay
    cd /tmp/buildyay && makepkg -o && makepkg -se && makepkg -i --noconfirm
    if [ $? -eq 0 ]; then
        show_success "yay-bin instalado correctamente (dots-hyprland version)."
        rm -rf /tmp/buildyay
    else
        show_error "Error al instalar yay-bin (dots-hyprland version)."
        exit 1
    fi
}

# Opción 2: Simple version (mi enfoque)
install_yay_simple() {
    show_info "Instalando yay (Simple version)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    if [ $? -eq 0 ]; then
        show_success "yay instalado correctamente (Simple version)."
        rm -rf /tmp/yay
    else
        show_error "Error al instalar yay (Simple version)."
        exit 1
    fi
}

# Función para seleccionar la versión de instalación de yay
select_yay_installation() {
    while true; do
        echo "Selecciona la versión de instalación de yay:"
        echo "1) dots-hyprland version (usa yay-bin)"
        echo "2) Simple version (instalación más automatizada)"
        read -p "Elige una opción (1 o 2): " option
        case $option in
            1 ) install_yay_dots_hyprland; break;;
            2 ) install_yay_simple; break;;
            * ) echo "Por favor, selecciona una opción válida (1 o 2).";;
        esac
    done
}

# Función para instalar yay si no está presente
install_yay() {
    if ! command -v yay > /dev/null; then
        select_yay_installation
    else
        show_info "yay ya está instalado."
    fi
}

# Función para instalar un paquete usando pacman o yay con verificación rigurosa
install_package() {
    local pkg=$1
    local install_all=$2
    local retries=3

    for ((i=1; i<=retries; i++)); do
        if pacman -Qs $pkg > /dev/null; then
            show_info "$pkg ya está instalado."
            return 0
        fi

        if [ "$install_all" = true ] || ask_install "$pkg"; then
            show_info "Intentando instalar $pkg (Intento $i/$retries)..."
            if sudo pacman -S --noconfirm $pkg; then
                show_success "$pkg instalado con éxito con pacman."
                return 0
            else
                show_info "No se pudo instalar $pkg con pacman. Intentando con yay..."
                if yay -S --noconfirm $pkg; then
                    show_success "$pkg instalado con éxito con yay."
                    return 0
                fi
            fi
        else
            show_info "$pkg omitido por el usuario."
            return 2
        fi

        show_error "Error al instalar $pkg. Reintentando..."
    done

    show_error "No se pudo instalar $pkg después de $retries intentos."
    return 1
}

# Función para verificar si la fuente CaskaydiaCove Nerd Font Mono ya está instalada
check_and_install_font() {
    local font_name="CaskaydiaCove Nerd Font Mono"
    
    if fc-list | grep -qi "$font_name"; then
        show_info "La fuente $font_name ya está instalada."
        return 0
    fi
    
    show_info "La fuente $font_name no está instalada. Intentando instalarla..."
    
    # Descargar la fuente
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/CascadiaCode.zip -O /tmp/CascadiaCode.zip
    if [ $? -ne 0 ]; then
        show_error "Error al descargar $font_name."
        return 1
    fi
    
    # Descomprimir y mover la fuente
    unzip /tmp/CascadiaCode.zip -d ~/.local/share/fonts
    if [ $? -ne 0 ]; then
        show_error "Error al descomprimir $font_name."
        return 1
    fi
    
    # Actualizar la caché de fuentes
    fc-cache -fv
    show_success "La fuente $font_name se instaló correctamente."
}

# Listas de paquetes, agrupadas por categoría para facilitar su mantenimiento
declare -a dotfiles_tools=(
    "stow"
    "git"
)

declare -a system_utilities=(
    "linux-headers"
    "curl"
    "unzip"
    "tree"
    "man-db"
    "eza"
    "os-prober"
    "less"
    "fzf"
    "zoxide"
    "ranger"
    "btop"
    "fastfetch"
    "vesktop"
    "chromium"
    "obsidian"
    "foliate"
    "veracrypt"
    "keepassxc"
    "spotify-launcher"
    "syncthing"
    "zathura"
    "zathura-pdf-mupdf"
    "telegram-desktop"
    "torbrowser-launcher"
    "openvpn"
    "protonvpn-cli-ng"
    "virtualbox"
    "virtualbox-host-modules-arch"
    "virtualbox-guest-iso"
    "obs-studio"
)

declare -a development_tools=(
    "neovim"
    "python"
    "python-pynvim"
    "npm"
    "python-virtualenv"
    "pyright"
    "go"
    "base-devel"
    "gcc"
    "lazygit"
)

declare -a tmux_plugins=(
    "tmux"
    "bc"
    "jq"
    "glab"
    "playerctl"
)

declare -a terminal_shell=(
    "kitty"
    "zsh"
    "pokemon-colorscripts-git"
)

declare -a fonts_symbols=(
    "noto-fonts"
    "noto-fonts-extra"
    "noto-fonts-emoji"
    "noto-fonts-cjk"
    "ttf-nerd-fonts-symbols"
    "ttf-nerd-fonts-symbols-mono"
)

# Función para instalar los paquetes de un grupo con contador
install_group() {
    local group_name=$1
    shift
    local packages=("$@")
    local install_all=$install_all

    show_info "Instalando grupo de paquetes: $group_name"
    local total_packages=${#packages[@]}
    for i in "${!packages[@]}"; do
        local pkg=${packages[$i]}
        show_info "Instalando paquete $((i+1))/$total_packages: $pkg"
        if install_package "$pkg" "$install_all"; then
            if pacman -Qs $pkg > /dev/null; then
                installed+=("$pkg (pacman)")
            else
                installed+=("$pkg (yay)")
            fi
        elif [ $? -eq 2 ]; then
            user_skipped+=("$pkg")
        else
            errors+=("$pkg")
        fi
    done
}

# Función para instalar todos los grupos de paquetes
install_packages() {
    local install_all=$1

    installed=()
    skipped=()
    user_skipped=()
    errors=()
    install_yay # Instalar yay primero

    install_group "Herramientas de Gestión de Dotfiles" "${dotfiles_tools[@]}"
    install_group "Utilidades Básicas del Sistema" "${system_utilities[@]}"
    install_group "Herramientas de Desarrollo y Python" "${development_tools[@]}"
    install_group "Tmux y Gestores de Plugins" "${tmux_plugins[@]}"
    install_group "Terminal y Shell" "${terminal_shell[@]}"
    install_group "Fuentes y Símbolos" "${fonts_symbols[@]}"

    check_and_install_font
    install_additional_tools
    show_summary
}

# Función para instalar herramientas adicionales (Tmux Plugin Manager, NvChad, Starship, Oh My Zsh)
install_additional_tools() {
    local tools_installed=0
    # Instalación de Tmux Plugin Manager (tpm)
    show_info "Instalando Tmux Plugin Manager (tpm)..."
    if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
        if [ $? -ne 0 ]; then
            show_error "Error al instalar tmux plugin manager (tpm)."
            errors+=("tpm")
        else
            show_success "Tmux Plugin Manager instalado con éxito."
            installed+=("tpm")
            tools_installed=$((tools_installed+1))
        fi
    else
        show_info "Tmux Plugin Manager ya está instalado."
        skipped+=("tpm")
    fi

    # Instalación de NvChad
    show_info "Instalando NvChad..."
    if [ ! -d "$HOME/.config/nvim" ]; then
        git clone https://github.com/NvChad/starter ~/.config/nvim
        if [ $? -ne 0 ]; then
            show_error "Error al instalar NvChad."
            errors+=("NvChad")
        else
            show_success "NvChad instalado con éxito."
            installed+=("NvChad")
            tools_installed=$((tools_installed+1))
        fi
    else
        show_info "NvChad ya está instalado."
        skipped+=("NvChad")
    fi

    # Instalación de Starship
    show_info "Instalando Starship..."
    if ! command -v starship > /dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- --yes
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Starship."
            errors+=("Starship")
        else
            show_success "Starship instalado con éxito."
            installed+=("Starship")
            tools_installed=$((tools_installed+1))
        fi
    else
        show_info "Starship ya está instalado."
        skipped+=("Starship")
    fi

    # Instalación de Oh My Zsh
    show_info "Instalando Oh My Zsh..."
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        if [ $? -ne 0 ]; then
            show_error "Error al instalar Oh My Zsh."
            errors+=("Oh My Zsh")
        else
            show_success "Oh My Zsh instalado con éxito."
            installed+=("Oh My Zsh")
            tools_installed=$((tools_installed+1))
        fi
    else
        show_info "Oh My Zsh ya está instalado."
        skipped+=("Oh My Zsh")
    fi

    show_info "Se han instalado $tools_installed herramientas adicionales."
}

# Función para mostrar el resumen de la instalación
show_summary() {
    show_info "-------------------------------------------"
    show_info "Resumen de la instalación"
    show_info "-------------------------------------------"
    show_info "Paquetes instalados:"
    for item in "${installed[@]}"; do
        show_success " - $item"
    done
    show_info "Paquetes ya estaban instalados:"
    for item in "${skipped[@]}"; do
        show_info " - $item"
    done
    show_info "Paquetes omitidos por el usuario:"
    for item in "${user_skipped[@]}"; do
        show_info " - $item"
    done
    show_info "Paquetes que fallaron:"
    for item in "${errors[@]}"; do
        show_error " - $item"
    done
}

# Preguntar si se desea instalar todo de una vez o uno por uno
read -p "¿Quieres instalar todos los paquetes de corrido? [s/n]: " install_all
if [[ $install_all =~ ^[Ss]$ ]]; then
    install_packages true
else
    install_packages false
fi
