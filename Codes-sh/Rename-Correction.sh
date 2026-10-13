#!/bin/bash

# --- CONFIGURACIÓN ---
#ARCHIVO_DATOS="Prova.txt"
ARCHIVO_DATOS="Strains-raw/IDs-Correspondences.txt"
DIRECTORIO_BASE="Strains-raw"

if [ ! -f "$ARCHIVO_DATOS" ]; then
    echo "Error: No se encuentra $ARCHIVO_DATOS"
    exit 1
fi

echo "Iniciando estandarización total..."

# Leer archivo saltando cabecera y quitando retornos de Windows
tail -n +2 "$ARCHIVO_DATOS" | tr -d '\r' | while read -r nuevo_nombre nombre_actual resto; do
    
    [ -z "$nuevo_nombre" ] && continue

    DIR_ACTUAL="${DIRECTORIO_BASE}/${nombre_actual}"
    DIR_NUEVO="${DIRECTORIO_BASE}/${nuevo_nombre}"

    # 1. Renombrar la carpeta
    if [ -d "$DIR_ACTUAL" ]; then
        mv "$DIR_ACTUAL" "$DIR_NUEVO"
        echo "Carpeta: '$nombre_actual' -> '$nuevo_nombre'"
    elif [ ! -d "$DIR_NUEVO" ]; then
        echo "Aviso: No existe carpeta original '$nombre_actual' ni destino '$nuevo_nombre'. Saltando."
        continue
    fi

    # 2. Estandarizar archivos dentro de la carpeta (Ya renombrada a $DIR_NUEVO)
    echo "  -> Estandarizando contenido de '$nuevo_nombre'..."
    
    # Procesar archivos FASTQ (busca R1 o R2 en el nombre actual)
    for f in "$DIR_NUEVO"/*; do
        [ -e "$f" ] || continue
        
        # Identificar si es R1 o R2
        if [[ "$f" == *"R1"* ]]; then
            mv "$f" "$DIR_NUEVO/${nuevo_nombre}_R1.${f##*.}" 2>/dev/null
        elif [[ "$f" == *"R2"* ]]; then
            mv "$f" "$DIR_NUEVO/${nuevo_nombre}_R2.${f##*.}" 2>/dev/null
        fi
    done
    
    # Procesar reportes FastQC (renombra manteniendo la extensión .html o .zip)
    for f in "$DIR_NUEVO"/*_fastqc.*; do
        [ -e "$f" ] || continue
        ext="${f##*.}"
        if [[ "$f" == *"R1"* ]]; then
            mv "$f" "$DIR_NUEVO/${nuevo_nombre}_R1_fastqc.$ext"
        elif [[ "$f" == *"R2"* ]]; then
            mv "$f" "$DIR_NUEVO/${nuevo_nombre}_R2_fastqc.$ext"
        fi
    done

done

echo "Proceso finalizado. Estructura normalizada."