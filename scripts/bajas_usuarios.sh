#!/bin/bash

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Este script debe ejecutarse con privilegios de root (sudo)." >&2
  exit 1
fi

echo "[+] Iniciando proceso de baja de usuarios..."

# Lista de usuarios a dar de baja (puedes modificarla según lo requieras)
USERS_TO_REMOVE=(
  "ana.gomez"
  "mateo.redes"
  "luis.perez"
  "sofia.auditor"
)

# Directorio donde se guardarán respaldos de seguridad antes de borrar el home
BACKUP_DIR="/var/backups/usuarios_bajas_$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

for username in "${USERS_TO_REMOVE[@]}"; do
  if ! id "$username" &>/dev/null; then
    echo "[i] El usuario $username no existe en el sistema. Omitiendo..."
    continue
  fi

  echo "[+] Procesando baja para el usuario: $username"

  # 1. Matar todos los procesos activos del usuario
  echo "    -> Cerrando sesiones y procesos activos..."
  pkill -u "$username"

  # 2. Respaldar el directorio Home antes de eliminarlo
  HOME_DIR=$(eval echo ~$username)
  if [ -d "$HOME_DIR" ]; then
    echo "    -> Respaldando directorio personal en $BACKUP_DIR..."
    tar -czf "$BACKUP_DIR/${username}_home.tar.gz" -C "$(dirname "$HOME_DIR")" "$(basename "$HOME_DIR")"
  fi

  # 3. Eliminar usuario y su directorio personal (-r)
  userdel -r "$username"

  if [ $? -eq 0 ]; then
    echo "[ok] Usuario $username eliminado correctamente."
  else
    echo "[-] Error al eliminar el usuario $username."
  fi
  echo "----------------------------------------"
done

echo "[+] Proceso de bajas finalizado con éxito."