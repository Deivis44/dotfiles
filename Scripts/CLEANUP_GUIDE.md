# 🧹 GUÍA DE LIMPIEZA - DOTFILES v2.0

## ✅ **NUEVO SISTEMA UNIFICADO**

### Scripts PRINCIPALES (mantener):
- `full_installer_v2.sh` → **Orquestador principal JSON-nativo**
- `packages.json` → **Base de datos central de paquetes**
- `json_manager.sh` → **Utilidad de gestión del JSON**
- `stow-links.sh` → **Enlaces simbólicos** (sin cambios)
- `install_extra_packs.sh` → **Paquetes adicionales** (sin cambios)

### Scripts ADICIONALES (mantener):
- `Additional/Pacman.sh` → Configuración avanzada de pacman
- `Additional/MineGRUB.sh` → Tema Minecraft para GRUB
- `Additional/fastfetch.sh` → Configuración de fastfetch
- `Additional/setup-bluetooth.sh` → Configuración de Bluetooth

### Scripts de UTILIDAD (mantener):
- `test_system.sh` → Framework de testing
- `rm-links.sh` → Utilidad para remover enlaces

---

## ❌ **SCRIPTS LEGACY PARA ELIMINAR**

```bash
# Scripts que ahora son obsoletos:
rm install-packages.sh           # Legacy con arrays hardcodeados
rm package_installer.sh          # Híbrido innecesario
rm installer_json_native.sh      # Integrado en full_installer_v2.sh
rm Full_Install.sh               # Versión legacy
rm migrate_to_json.sh           # Ya no necesario
rm full_installer_v2.sh.backup  # Backup temporal
```

---

## 🚀 **NUEVO FLUJO DE TRABAJO**

### **1. Instalación Completa**
```bash
./full_installer_v2.sh
```

### **2. Solo gestión de JSON**
```bash
./json_manager.sh validate      # Validar packages.json
./json_manager.sh stats         # Estadísticas
./json_manager.sh list-categories  # Listar categorías
```

### **3. Testing del sistema**
```bash
./test_system.sh
```

---

## 📦 **ARQUITECTURA SIMPLIFICADA**

```
Scripts/
├── full_installer_v2.sh    # 🎯 SCRIPT PRINCIPAL
├── packages.json           # 📊 BASE DE DATOS
├── json_manager.sh         # 🔧 UTILIDADES
├── stow-links.sh          # 🔗 ENLACES
├── install_extra_packs.sh # 📦 EXTRAS
├── test_system.sh         # 🧪 TESTING
└── Additional/            # ⚙️  TWEAKS
    ├── Pacman.sh
    ├── MineGRUB.sh
    ├── fastfetch.sh
    └── setup-bluetooth.sh
```

---

## ⚡ **VENTAJAS DEL NUEVO SISTEMA**

✅ **Un solo punto de entrada** (`full_installer_v2.sh`)  
✅ **JSON como fuente única de verdad**  
✅ **Flujo modular en 3 fases**:
- 📦 **Fase 1**: Paquetes (JSON-nativo)
- 🔧 **Fase 2**: Configuraciones adicionales
- 🔗 **Fase 3**: Enlaces simbólicos

✅ **Logging completo** con timestamps  
✅ **Contadores globales** de instalación  
✅ **4 modos de instalación**:
- Completa
- Por categorías 
- Selectiva
- Solo obligatorios

✅ **Compatibilidad total** con sistema existente  
✅ **Sin dependencias legacy**
