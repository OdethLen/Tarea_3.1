# Tarea 3.1: Gestión Automatizada de Usuarios, Directivas y Control de Acceso por PAM

## 📌 Descripción del Proyecto
Este módulo contiene la implementación completa para la automatización del ciclo de vida de usuarios (altas y bajas), la asignación de restricciones de seguridad (`umask`, aislamiento de directorios `home`) y la aplicación de políticas de control de acceso por horario utilizando el módulo de PAM `pam_time.so`.

---

## 📁 Estructura del Repositorio

```text
Unidad_3/Tarea_3.1/
├── README.md
├── scripts/
│   ├── gestion_usuarios.sh
│   └── bajas_usuarios.sh
└── config/
    ├── time.conf
    └── sudoers_netops
```

---

## 📊 Matriz de Configuración de Usuarios y Permisos

### 1. Estructura de Grupos, Rutas y Máscara de Permisos

| Departamento | Grupo Primario | Grupo Secundario | Home Directory | Máscara de Permisos |
| :--- | :--- | :--- | :--- | :--- |
| **Administrador** | `g_sistemas` | `sysadmins`, `sudo` | `/home/sys_<usuario>` | `0022` (`drwxr-xr-x`) |
| **Ing. Redes** | `g_sistemas` | `netops` | `/home/sys_<usuario>` | `0022` (`drwxr-xr-x`) |
| **Analista Financiero** | `g_finanzas` | `p_financiero` | `/home/fin_<usuario>` | `0077` (`drwx------`) |
| **Supervisor de Operaciones** | `g_operaciones` | `g_operaciones` | `/home/ops_<usuario>` | `0027` (`drwxr-x---`) |
| **Auditor Externo** | `g_rh` | `auditores` | `/home/aud_<usuario>` | `0077` (`drwx------`) |

---

### 2. Niveles de Privilegios y Restricciones Horarias

| Nivel de Privilegios | Restricción Horaria |
| :--- | :--- |
| **Root Total:** Nivel `/etc/sudoers` completo (`ALL=(ALL:ALL) ALL`). | **Sin restricción (24/7).** |
| **Sudo Restringido:** Solo comandos de red (`systemctl status`, `ip`, `tcpdump`). | **Lunes a Viernes (07:00 - 21:00).** |
| **Usuario Estándar:** Sin acceso a `sudo`. Sin lectura de logs del sistema. | **Lunes a Viernes (08:00 - 18:00).** |
| **Usuario Estándar:** Ejecución de scripts locales en `/srv/operaciones`. | **Lunes a Sábado (06:00 - 22:00).** |
| **Lectura Única:** Lectura sobre `/var/log/` y `/srv/reportes`. Sin `sudo`. | **Lunes a Viernes (09:00 - 17:00).** Cuenta con **expiración corta**. |

---

## ⚙️ Guía de Ejecución

### 1. Permisos de Ejecución
Asegúrate de otorgar permisos de ejecución a los scripts antes de utilizarlos:
```bash
chmod +x scripts/gestion_usuarios.sh scripts/bajas_usuarios.sh
```

### 2. Alta Automatizada de Usuarios
Para ejecutar el provisionamiento de grupos, usuarios, aislamiento de carpetas `home`, `umask` y cambio obligatorio de contraseña en el primer login:
```bash
sudo ./scripts/gestion_usuarios.sh
```

### 3. Configuración del Módulo PAM Time
1. Copiar la configuración de reglas horarias a `/etc/security/time.conf`:
   ```bash
   sudo cp config/time.conf /etc/security/time.conf
   ```
2. Asegurar que la directiva esté activa en `/etc/pam.d/su` y `/etc/pam.d/sshd`:
   ```text
   account required pam_time.so
   ```

### 4. Baja y Respaldo Automatizado
Para cerrar sesiones activas, generar un archivo comprimido (`.tar.gz`) de respaldo del directorio personal y eliminar las cuentas:
```bash
sudo ./scripts/bajas_usuarios.sh
```

---

## 🔍 Validación del Sistema
* **Control de Horarios:** El intento de inicio de sesión o cambio de usuario (`su - <usuario>`) fuera del horario especificado devuelve inmediatamente `su: Permission denied`.
* **Aislamiento de Privilegios:** Los usuarios no configurados en `sudoers` reciben la denegación implícita al intentar ejecutar comandos administrativos.
