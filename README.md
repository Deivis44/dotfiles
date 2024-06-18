
# Dotfiles

## Introducción
Este repositorio contiene mis archivos de configuración (dotfiles) para diversas aplicaciones y herramientas que uso en mi entorno de desarrollo. La finalidad de este repositorio es facilitar la configuración y personalización de nuevas máquinas, así como mantener un entorno consistente en diferentes dispositivos.

## Preparación Inicial

### Clonar el Repositorio
Para comenzar, clona el repositorio de dotfiles en tu directorio home:

```bash
cd ~
git clone https://github.com/tu-usuario/dotfiles.git
cd dotfiles
```

## Estructura del Repositorio
La estructura del repositorio está organizada de manera que refleje las ubicaciones deseadas de los archivos de configuración en tu sistema. A continuación, se muestra un ejemplo de cómo debería lucir la estructura para tmux y .zshrc:

```md
dotfiles/
├── zsh/
│   └── .zshrc
└── tmux/
    └── .config/
        └── tmux/
            └── tmux.conf
```

## Manejo de Archivos de Configuración Existentes
### Procedimiento

Si ya tienes archivos de configuración existentes en tu máquina, sigue estos pasos para añadirlos al repositorio de dotfiles y crear un backup de los originales:

1. Hacer una copia del archivo existente en tu máquina:
```bash
cp ~/.config/tmux/tmux.conf ~/dotfiles/tmux/.config/tmux/
```

2. Renombrar el archivo local como backup:
```bash
mv ~/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf.backup
```

3. Ahora el archivo de configuración está listo para ser gestionado por el script install.sh.

#### Ejemplo: Archivo en .config
Supongamos que tienes un archivo de configuración para tmux en ~/.config/tmux/tmux.conf. El procedimiento sería:

1. Copia el archivo al repositorio de dotfiles:
```bash
cp ~/.config/tmux/tmux.conf ~/dotfiles/tmux/.config/tmux/
```

2. Renombra el archivo local como backup:
```bash
mv ~/.config/tmux/tmux.conf ~/.config/tmux/tmux.conf.backup
```
3. Ahora el archivo de configuración está listo para ser gestionado por el script install.sh.

#### Ejemplo: Archivo en Home
Supongamos que tienes un archivo de configuración para zsh en ~/.zshrc. El procedimiento sería:

1. Copia el archivo al repositorio de dotfiles:
```bash
cp ~/.zshrc ~/dotfiles/zsh/
```

2. Renombra el archivo local como backup:
```bash
mv ~/.zshrc ~/.zshrc.backup
```

3. Ahora el archivo de configuración está listo para ser gestionado por el script install.sh.


## Creación de Enlaces Simbólicos para Archivos No Existentes
### Procedimiento
Para crear nuevos enlaces simbólicos basados en los dotfiles del repositorio, simplemente ejecuta el script install.sh. El script se encargará de crear los enlaces simbólicos necesarios.

### Ejemplo
Si no tienes configuraciones previas para tmux, el script install.sh creará los enlaces simbólicos necesarios en la ubicación correcta (~/.config/tmux/tmux.conf).


## Añadiendo Más Dotfiles Basados en Archivos Existentes
### Procedimiento General
1. Identificar el archivo de configuración existente.
2. Copiar el archivo al repositorio de dotfiles.
3. Renombrar el archivo local como backup.
4. Añadir la ruta correspondiente en el script install.sh.

### Ejemplo: Archivo en Home
Supongamos que tienes un archivo de configuración para vim en ~/.vimrc:

1. Copia el archivo al repositorio de dotfiles:
```bash
cp ~/.vimrc ~/dotfiles/vim/
```

2. Renombra el archivo local como backup:
```bash
cp ~/.vimrc ~/dotfiles/vim/
```
3. Añade la ruta en el script install.sh:
```bash
# Dentro del script install.sh
add_dotfile "vim" ".vimrc"
```
### Ejemplo: Archivo en Home
Supongamos que tienes un archivo de configuración para `ranger` en `~/.config/ranger/rc.conf`:
1. Copia el archivo al repositorio de dotfiles:
```bash
cp ~/.config/ranger/rc.conf ~/dotfiles/ranger/.config/ranger/
```

2. Renombra el archivo local como backup:
```bash
mv ~/.config/ranger/rc.conf ~/.config/ranger/rc.conf.backup
```
3. Añade la ruta en el script install.sh:
```bash
# Dentro del script install.sh
add_dotfile "ranger" ".config/ranger"
```


## Ejecutando el Script install.sh
### Instrucciones
1. Dar permisos de ejecución al script:
```bash
chmod +x install.sh
```
2. Ejecutar el script:
```bash
./install.sh
```

### ¿Qué hace el script?
- Instalación de stow: Verifica si stow está instalado y lo instala si es necesario.
- Backup de archivos existentes: Crea backups de archivos de configuración existentes que no sean enlaces simbólicos.
- Creación de enlaces simbólicos: Usa stow para crear los enlaces simbólicos basados en los dotfiles del repositorio.
- Instalación de Starship: Instala Starship automáticamente sin pedir confirmación.
- Instalación del Plugin Manager de tmux (TPM): Clona el repositorio de TPM en la ubicación correcta.

### Resumen del Script
El script proporcionará un resumen detallado al final de la ejecución, indicando:

1. Enlaces nuevos creados y ubicación: Lista los enlaces simbólicos nuevos creados.
2. Archivos o carpetas respaldados: Lista los archivos o carpetas que fueron respaldados.
3. Enlaces existentes omitidos: Indica los enlaces simbólicos ya existentes que fueron omitidos.

```md
Resumen de la instalación
---------------------------
Enlaces nuevos creados y ubicaciones:
 - /home/usuario/.config/tmux/tmux.conf
 - /home/usuario/.zshrc
 - ...

---------------------------
Archivos o carpetas ya existentes que fueron respaldados:
 - /home/usuario/.config/tmux/tmux.conf.backup
 - /home/usuario/.zshrc.backup
 - ...

---------------------------
Enlaces ya existentes que fueron omitidos:
 - /home/usuario/.config/ranger/rc.conf
 - ...
```


## Desinstalando Configuraciones con uninstall.sh

El script `uninstall.sh` deshace los cambios realizados por el `install.sh`, eliminando los enlaces simbólicos y creando backups de los archivos originales.

### Instrucciones

1. Dar permisos de ejecución al script:
```bash
chmod +x uninstall.sh
```
2. Ejecutar el script:
```bash
./uninstall.sh
```

### ¿Qué hace el script?
-   **Eliminar enlaces simbólicos**: Elimina los enlaces simbólicos creados por `install.sh`.
-   **Crear backups de los archivos originales**: Antes de eliminar un enlace simbólico, el script crea un backup del archivo original al que apunta el enlace.

### Resumen del Script
El script proporcionará un resumen detallado al final de la ejecución, indicando:

1.  Enlaces eliminados y ubicaciones respaldadas: Lista los enlaces simbólicos eliminados y los archivos respaldados.
```md
Resumen de la desinstalación
---------------------------
Enlaces eliminados y ubicaciones respaldadas:
 - /home/usuario/.config/tmux/tmux.conf
 - /home/usuario/.zshrc
 - ...

---------------------------
Archivos de destino respaldados:
 - /home/usuario/.config/tmux/tmux.conf.unlink_2024-06-18_10:00:00
 - /home/usuario/.zshrc.unlink_2024-06-18_10:00:00
 - ...
```
