#!/bin/bash

show_banner() {
    echo -e "
     _____          ___         ___
    /  /::\        /  /\       /__/\
   /  /:/\:\      /  /::\     |  |::\
  /  /:/  \:\    /  /:/\:\    |  |:|:\
 /__/:/ \__\:|  /  /:/~/:/  __|__|:|\:\
 \  \:\ /  /:/ /__/:/ /:/  /__/::::| \:\
  \  \:\  /:/  \  \:\/:/   \  \:\~~\__\/
   \  \:\/:/    \  \::/     \  \:\
    \  \::/      \  \:\      \  \:\
     \__\/        \  \:\      \  \:\
                   \__\/       \__\/
    "
}

show_banner

# Funciones para mostrar mensajes al usuario
show_info() {
    local message=$1
    echo -e "\e[1;33m$message\e[0m"
}

show_error() {
    local message=$1
    echo -e "\e[1;31m$message\e[0m"
}

show_success() {
    local message=$1
    echo -e "\e[1;32m$message\e[0m"
}

# Función para preguntar al usuario
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

# Función para verificar si un paquete está instalado
is_installed() {
    local pkg=$1
    if pacman -Qi "$pkg" > /dev/null 2>&1 || yay -Qi "$pkg" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para instalar yay si no está presente
install_yay() {
    if ! command -v yay > /dev/null; then
        show_info "Instalando yay..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay && makepkg -si --noconfirm
        if [ $? -eq 0 ]; then
            show_success "yay instalado correctamente."
            rm -rf /tmp/yay
        else
            show_error "Error al instalar yay."
            exit 1
        fi
    else
        show_info "yay ya está instalado."
    fi
}

# Función para instalar un paquete
install_package() {
    local pkg=$1
    local install_all=$2

    if is_installed $pkg; then
        show_info "$pkg ya está instalado."
        return 0
    fi

    if [ "$install_all" = true ] || ask_install "$pkg"; then
        show_info "Instalando $pkg..."
        if sudo pacman -S --noconfirm $pkg; then
            show_success "$pkg instalado con éxito con pacman."
            return 0
        else
            show_info "No se pudo instalar $pkg con pacman. Intentando con yay..."
            if yay -S --noconfirm $pkg; then
                show_success "$pkg instalado con éxito con yay."
                return 0
            else
                show_error "Error al instalar $pkg."
                return 1
            fi
        fi
    else
        show_info "$pkg omitido por el usuario."
        return 2
    fi
}

# Función para instalar grupos de paquetes
install_group() {
    local group_name=$1
    shift
    local packages=("$@")
    local install_all=$install_all

    show_info "-------------------------------------------"
    show_info "Instalando grupo de paquetes: $group_name"
    show_info "-------------------------------------------"
    local total_packages=${#packages[@]}
    for i in "${!packages[@]}"; do
        local pkg=${packages[$i]}
        show_info "[$((i+1))/$total_packages] Instalando: $pkg"
        if install_package "$pkg" "$install_all"; then
            installed+=("$pkg")
        elif [ $? -eq 2 ]; then
            user_skipped+=("$pkg")
        else
            errors+=("$pkg")
        fi
    done
}

# Función para instalar herramientas adicionales
install_additional_tools() {
    show_info "-------------------------------------------"
    show_info "Instalando herramientas adicionales"
    show_info "-------------------------------------------"

    # 1. Tmux Plugin Manager (tpm)
    if ask_install "Tmux Plugin Manager (tpm)"; then
        # Verificar si Tmux está instalado
        if ! command -v tmux > /dev/null; then
            show_info "Tmux no está instalado."
            if ask_install "Tmux"; then
                install_package "tmux" true
            else
                show_info "No se puede instalar tpm sin Tmux. Omitiendo."
                user_skipped+=("tpm")
                return
            fi
        fi

        if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
            show_info "Instalando Tmux Plugin Manager (tpm)..."
            git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
            if [ $? -ne 0 ]; then
                show_error "Error al instalar tpm."
                errors+=("tpm")
            else
                show_success "tpm instalado con éxito."
                installed+=("tpm")
            fi
        else
            show_info "tpm ya está instalado."
            skipped+=("tpm")
        fi
    fi

    # 2. NvChad
    if ask_install "NvChad (configuración de Neovim)"; then
        # Verificar si Neovim está instalado
        if ! command -v nvim > /dev/null; then
            show_info "Neovim no está instalado. Instalándolo..."
            install_package "neovim" true
        fi

        if [ ! -d "$HOME/.config/nvim" ]; then
            show_info "Instalando NvChad..."
            git clone https://github.com/NvChad/starter ~/.config/nvim
            if [ $? -ne 0 ]; then
                show_error "Error al instalar NvChad."
                errors+=("NvChad")
            else
                show_success "NvChad instalado con éxito."
                installed+=("NvChad")
            fi
        else
            show_info "NvChad ya está instalado."
            skipped+=("NvChad")
        fi
    fi

    # 3. Starship
    if ask_install "Starship (prompt personalizado)"; then
        if ! command -v starship > /dev/null; then
            show_info "Instalando Starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- --yes
            if [ $? -ne 0 ]; then
                show_error "Error al instalar Starship."
                errors+=("Starship")
            else
                show_success "Starship instalado con éxito."
                installed+=("Starship")
            fi
        else
            show_info "Starship ya está instalado."
            skipped+=("Starship")
        fi
    fi

    # 4. Doom en la terminal
    if ask_install "Doom en la terminal"; then
        # Verificar si Kitty está instalado
        if ! command -v kitty > /dev/null; then
            show_info "Kitty no está instalado. Instalándolo..."
            install_package "kitty" true
        fi

        # Instalar Zig (necesario para Doom en la terminal)
        if ! command -v zig > /dev/null; then
            show_info "Zig no está instalado. Instalándolo..."
            install_package "zig" true
        fi

        # Clonar y construir Doom en la terminal
        if [ ! -d "$HOME/terminal-doom" ]; then
            show_info "Instalando Doom en la terminal..."
            git clone https://github.com/cryptocode/terminal-doom.git "$HOME/terminal-doom"
            cd "$HOME/terminal-doom"
            zig build -Doptimize=ReleaseFast
            if [ $? -ne 0 ]; then
                show_error "Error al construir Doom en la terminal."
                errors+=("Doom en la terminal")
            else
                show_success "Doom en la terminal instalado con éxito."
                installed+=("Doom en la terminal")
            fi
            cd -
        else
            show_info "Doom en la terminal ya está instalado."
            skipped+=("Doom en la terminal")
        fi

        # Proporcionar instrucciones para añadir el alias manualmente
        show_info "Para ejecutar Doom en la terminal, puedes añadir el siguiente alias a tu archivo .zshrc:"
        echo -e "\e[1;32malias doom-zig='${HOME}/terminal-doom/zig-out/bin/terminal-doom'\e[0m"
    fi
}

# Función para mostrar el resumen de la instalación
show_summary() {
    show_info "-------------------------------------------"
    show_info "Resumen de la instalación"
    show_info "-------------------------------------------"
    if [ ${#installed[@]} -ne 0 ]; then
        show_info "Paquetes instalados:"
        for item in "${installed[@]}"; do
            show_success " - $item"
        done
    fi
    if [ ${#skipped[@]} -ne 0 ]; then
        show_info "Paquetes ya estaban instalados:"
        for item in "${skipped[@]}"; do
            show_info " - $item"
        done
    fi
    if [ ${#user_skipped[@]} -ne 0 ]; then
        show_info "Paquetes omitidos por el usuario:"
        for item in "${user_skipped[@]}"; do
            show_info " - $item"
        done
    fi
    if [ ${#errors[@]} -ne 0 ]; then
        show_info "Paquetes que fallaron:"
        for item in "${errors[@]}"; do
            show_error " - $item"
        done
    fi
}

# Declaración de arrays para agrupar paquetes por funcionalidad
declare -a installed
declare -a skipped
declare -a user_skipped
declare -a errors

# 1. Gestión de dotfiles y control de versiones
declare -a dotfiles_tools=(
    "stow"      # Gestiona tus dotfiles mediante enlaces simbólicos
    "git"       # Control de versiones para gestionar tu código
)

# 2. Utilidades del sistema
declare -a system_utilities=(
    "linux-headers"          # Cabeceras del kernel necesarias para ciertos módulos
    "curl"                   # Transferencia de datos con URL sintáctica
    "unzip"                  # Descompresión de archivos ZIP
    "tree"                   # Visualización de directorios en formato de árbol
    "man-db"                 # Páginas de manual para comandos
    "eza"                    # Reemplazo moderno y colorido de 'ls'
    "os-prober"              # Detecta otros sistemas operativos instalados
    "less"                   # Visualizador de archivos en terminal
    "fzf"                    # Fuzzy finder para búsquedas rápidas
    "zoxide"                 # Navegación eficiente entre directorios
    "ranger"                 # Administrador de archivos en consola
    "btop"                   # Monitorización de recursos del sistema
    "fastfetch"              # Información del sistema en terminal
    "tty-clock"              # Reloj en la terminal
    "cbonsai"                # Generador de bonsáis ASCII
    "vesktop"                # Herramienta para gestionar escritorios virtuales
    "cava"                   # Visualizador de audio en terminal
    "bat"                    # Reemplazo de 'cat' con resaltado de sintaxis
)

# 3. Aplicaciones de productividad y multimedia
declare -a productivity_apps=(
    "chromium"               # Navegador web
    "obsidian"               # Aplicación de toma de notas y conocimiento
    "foliate"                # Lector de libros electrónicos
    "veracrypt"              # Cifrado de discos y contenedores
    "keepassxc"              # Gestor de contraseñas
    "spotify-launcher"       # Cliente de Spotify
    "syncthing"              # Sincronización de archivos entre dispositivos
    "zathura"                # Visor de documentos ligero
    "zathura-pdf-mupdf"      # Backend PDF para Zathura
    "telegram-desktop"       # Cliente de mensajería
    "torbrowser-launcher"    # Navegación anónima con Tor
    "openvpn"                # Cliente VPN
    "protonvpn-cli-ng"       # Cliente de ProtonVPN
    "virtualbox"             # Virtualización de sistemas operativos
    "virtualbox-host-modules-arch"  # Módulos del kernel para VirtualBox
    "virtualbox-guest-iso"   # ISO de adiciones de huésped para VirtualBox
    "obs-studio"             # Grabación y streaming de video
    "minecraft-launcher"     # Juego de construcción y aventuras
    "thunderbird"            # Cliente de correo electrónico
    "onlyoffice-bin"         # Suite de office
)

# 4. Herramientas de desarrollo y programación
declare -a development_tools=(
    "neovim"                 # Editor de texto avanzado
    "python"                 # Lenguaje de programación Python
    "python-pynvim"          # Integración de Python con Neovim
    "npm"                    # Gestor de paquetes para Node.js
    "python-virtualenv"      # Entornos virtuales para Python
    "pyright"                # Analizador estático de tipos para Python
    "go"                     # Lenguaje de programación Go
    "base-devel"             # Herramientas básicas de desarrollo
    "gcc"                    # Compilador de C y C++
    "lazygit"                # Interfaz de Git en terminal
    "zig"                    # Lenguaje de programación Zig (necesario para Doom en la terminal)
    "jdk21-openjdk"          # Kit de desarrollo de Java
)

# 5. Terminal y shell
declare -a terminal_shell=(
    "kitty"                  # Emulador de terminal rápido y personalizable
    "zsh"                    # Shell avanzado
    "pokemon-colorscripts-git"  # Scripts de colores con temática Pokémon
)

# 6. Fuentes y símbolos
declare -a fonts_symbols=(
    "noto-fonts"                 # Fuentes Noto estándar
    "noto-fonts-extra"           # Fuentes Noto adicionales
    "noto-fonts-emoji"           # Soporte para emojis
    "noto-fonts-cjk"             # Soporte para caracteres chinos, japoneses y coreanos
    "ttf-nerd-fonts-symbols"     # Símbolos para prompt y plugins
    "ttf-nerd-fonts-symbols-mono" # Variante monoespaciada de símbolos
)

# 7. Herramientas y plugins para Tmux
declare -a tmux_plugins=(
    "tmux"                  # Multiplexor de terminal
    "bc"                    # Calculadora de precisión arbitraria
    "jq"                    # Procesador de JSON en línea de comandos
    "glab"                  # Interfaz de línea de comandos para GitLab
    "playerctl"             # Control de reproducción multimedia desde la terminal
)

# Función principal para instalar todos los paquetes
install_packages() {
    local install_all=$1

    install_yay

    install_group "Gestión de Dotfiles y Control de Versiones" "${dotfiles_tools[@]}"
    install_group "Utilidades del Sistema" "${system_utilities[@]}"
    install_group "Aplicaciones de Productividad y Multimedia" "${productivity_apps[@]}"
    install_group "Herramientas de Desarrollo y Programación" "${development_tools[@]}"
    install_group "Terminal y Shell" "${terminal_shell[@]}"
    install_group "Fuentes y Símbolos" "${fonts_symbols[@]}"
    install_group "Herramientas y Plugins para Tmux" "${tmux_plugins[@]}"

    install_additional_tools
    show_summary

    # Cambiar la shell por defecto a zsh
    if ask_install "¿Deseas cambiar la shell por defecto a zsh?"; then
        show_info "Cambiando la shell por defecto a zsh..."
        chsh -s $(which zsh)
    fi

    # Abrir y cerrar Kitty para generar archivos de configuración
    if command -v kitty > /dev/null; then
        show_info "Abriendo Kitty para generar archivos de configuración..."
        kitty &
        sleep 2
        killall kitty
    fi
}

# Preguntar si se desea instalar todo de una vez o uno por uno
read -p "¿Quieres instalar todos los paquetes de corrido? [s/n]: " install_all
if [[ $install_all =~ ^[Ss]$ ]]; then
    install_packages true
else
    install_packages false
fi
