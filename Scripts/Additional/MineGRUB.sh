#!/bin/bash

# Mostrar banner de inicio del script
echo -e "\e[1;32mIniciando instalación y configuración de temas personalizados de GRUB...\e[0m"

# Función para instalar los temas de GRUB de Minecraft
install_grub_themes() {
    echo "Instalando temas de GRUB de Minecraft..."

    # Verificar e instalar el tema "minegrub-world-selection"
    if [ -d "/boot/grub/themes/minegrub-world-selection" ]; then
        echo "El tema 'minegrub-world-selection' ya está instalado. No se volverá a instalar."
    else
        git clone https://github.com/Lxtharia/minegrub-world-sel-theme.git
        cd minegrub-world-sel-theme
        sudo cp -ruv minegrub-world-selection /boot/grub/themes/
        cd ..
    fi

    # Verificar e instalar el tema "minegrub"
    if [ -d "/boot/grub/themes/minegrub" ]; then
        echo "El tema 'minegrub' ya está instalado. No se volverá a instalar."
    else
        git clone https://github.com/Lxtharia/minegrub-theme.git
        cd minegrub-theme
        sudo cp -ruv minegrub /boot/grub/themes/
        cd ..
    fi
}

# Función para configurar el tema en /etc/default/grub
configure_grub_theme() {
    echo "Configurando el tema personalizado en /etc/default/grub..."
    
    # Configurar GRUB_TIMEOUT_STYLE y GRUB_THEME
    sudo sed -i 's/^GRUB_TIMEOUT_STYLE=.*/GRUB_TIMEOUT_STYLE=menu/' /etc/default/grub
    if grep -q "^GRUB_THEME=" /etc/default/grub; then
        current_theme=$(grep "^GRUB_THEME=" /etc/default/grub | cut -d'=' -f2)
        echo "Tema actual de GRUB: $current_theme"
        echo "El tema se cambiará a: /boot/grub/themes/minegrub-world-selection/theme.txt"
        sudo sed -i 's|^GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/minegrub-world-selection/theme.txt"|' /etc/default/grub
    else
        echo 'GRUB_THEME="/boot/grub/themes/minegrub-world-selection/theme.txt"' | sudo tee -a /etc/default/grub
    fi
}

# Función para configurar GRUB_CMDLINE_LINUX_DEFAULT
configure_grub_cmdline() {
    echo "Configurando parámetros de GRUB_CMDLINE_LINUX_DEFAULT..."

    # Verificar y agregar loglevel=3 y watchdog
    if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub; then
        current_cmdline=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT" /etc/default/grub | cut -d'"' -f2)
        echo "Parámetros actuales: $current_cmdline"
        new_cmdline="${current_cmdline} loglevel=3 watchdog"
        sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$new_cmdline\"|" /etc/default/grub
        echo "Nuevos parámetros configurados: $new_cmdline"
    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 watchdog"' | sudo tee -a /etc/default/grub
    fi
}

# Función para instalar archivos adicionales para el menú doble
install_double_menu() {
    echo "Instalando archivos adicionales para el menú doble..."

    # Clonar el repositorio y copiar archivos
    git clone https://github.com/Lxtharia/minegrub-double-menu.git
    cd minegrub-double-menu

    # Verificar si los archivos ya existen
    if [ -f "/boot/grub/mainmenu.cfg" ]; then
        echo "El archivo mainmenu.cfg ya existe en /boot/grub/. Sobrescribiéndolo."
    fi
    sudo cp ./mainmenu.cfg /boot/grub/

    if [ -f "/etc/grub.d/05_twomenus" ]; then
        echo "El archivo 05_twomenus ya existe en /etc/grub.d/. Sobrescribiéndolo."
    fi
    sudo cp ./05_twomenus /etc/grub.d/
    sudo chmod +x /etc/grub.d/05_twomenus
    cd ..
}

# Función para aplicar los cambios y regenerar grub.cfg
apply_grub_changes() {
    echo "Aplicando cambios y regenerando grub.cfg..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Función para configurar la variable ambiental de GRUB para el menú doble
set_grub_environment_variable() {
    echo "Configurando variable ambiental para habilitar el menú doble en GRUB..."
    sudo grub-editenv - set config_file=mainmenu.cfg
}

# Ejecutar funciones en orden
install_grub_themes
configure_grub_theme
configure_grub_cmdline
install_double_menu
apply_grub_changes
set_grub_environment_variable

# Mensajes finales
echo -e "\e[1;32mInstalación y configuración de temas de GRUB completadas.\e[0m"
echo "Reinicia la máquina para ver los cambios en el inicio de GRUB."

