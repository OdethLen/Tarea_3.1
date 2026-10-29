#!/bin/bash

# Verificar si se ejecuta como superusuario
if [ "$EUID" -ne 0 ]; then
  echo "[-] Error: Este script debe ejecutarse con privilegios de root (sudo)." >&2
  exit 1
fi

echo "[+] Creando grupos de trabajo..."

# 1. Creación directa y segura de grupos
groupadd -f g_sistemas
groupadd -f g_finanzas
groupadd -f g_operaciones
groupadd -f g_rh
groupadd -f sysadmins
groupadd -f netops
groupadd -f p_financiero
groupadd -f auditores

echo "[ok] Grupos creados o verificados con éxito."
echo "----------------------------------------"

# 2. Arreglo de Usuarios (Formato: usuario:password:g_primario:g_secundario:home:umask:expiracion)
USERS=(
  "carlos.mendoza:TempSys2026_#:g_sistemas:sysadmins:/home/sys_carlos.mendoza:0022:2027-12-31"
  "mateo.redes:TempNet2026_#:g_sistemas:netops:/home/sys_mateo.redes:0022:2027-12-31"
  "ana.gomez:TempFin2026_#:g_finanzas:p_financiero:/home/fin_ana.gomez:0077:2027-06-30"
  "luis.perez:TempOps2026_#:g_operaciones:g_operaciones:/home/ops_luis.perez:0027:2027-06-30"
  "sofia.auditor:TempAud2026_#:g_rh:auditores:/home/aud_sofia.auditor:0077:2026-11-30"
)

for entry in "${USERS[@]}"; do
  IFS=':' read -r username password primary_group secondary_group home_dir umask_val expire_date <<< "$entry"

  if id "$username" &>/dev/null; then
    echo "[i] El usuario $username ya existe. Omitiendo..."
    continue
  fi

  # Crear usuario indicando su directorio personalizado
  useradd -m -d "$home_dir" -s /bin/bash -g "$primary_group" -G "$secondary_group" -e "$expire_date" "$username"

  if [ $? -eq 0 ]; then
    # Asignar contraseña temporal
    echo "$username:$password" | chpasswd

    # Forzar cambio de contraseña en el primer login
    chage -d 0 "$username"

    # Configurar umask en el .bashrc
    if [ -f "$home_dir/.bashrc" ]; then
      echo "umask $umask_val" >> "$home_dir/.bashrc"
      chown "$username:$primary_group" "$home_dir/.bashrc"
    fi

    echo "[ok] Usuario configurado con éxito: $username"
  else
    echo "[-] Error al crear el usuario $username."
  fi
done

echo "----------------------------------------"
echo "[+] Proceso finalizado."