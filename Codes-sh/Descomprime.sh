#!/bin/bash

# --- CONFIGURACIÓN ---
#ARCHIVO_DATOS="Prova.txt"
ARCHIVO_DATOS="Strains-raw/IDs-Correspondences.txt"
DIRECTORIO_BASE="Strains-raw"

if [ ! -f "$ARCHIVO_DATOS" ]; then
    echo "Error: No se encuentra el archivo $ARCHIVO_DATOS"
    exit 1
fi

echo "Iniciando procesamiento de secuencias (descompresión + FastQC)..."

tail -n +2 "$ARCHIVO_DATOS" | tr -d '\r' | while read -r nuevo_nombre nombre_actual resto; do
    [ -z "$nuevo_nombre" ] && continue

    DIR_ACTUAL="${DIRECTORIO_BASE}/${nombre_actual}"
    NUEVA_RUTA="${DIRECTORIO_BASE}/${nuevo_nombre}"

    # 1. Renombrar carpeta
    if [ -d "$DIR_ACTUAL" ]; then
        mv "$DIR_ACTUAL" "$NUEVA_RUTA"
        echo "Carpeta renombrada: '$nombre_actual' -> '$nuevo_nombre'"
    fi

    if [ ! -d "$NUEVA_RUTA" ]; then continue; fi

    printf "_________________________________(Start %s)____________________________\n" "${nuevo_nombre}"

    # --- Función interna para procesar R1 y R2 ---
    procesar_lectura() {
        local tipo=$1 # R1 o R2
        local ruta_base=$2
        local nombre_cepa=$3
        
        # Buscamos .gz o .fastq existente
        local archivo_gz=$(find "${ruta_base}" -maxdepth 1 -type f -name "*${tipo}*.gz" | head -n 1)
        local archivo_fq=$(find "${ruta_base}" -maxdepth 1 -type f -name "${nombre_cepa}_${tipo}.fastq" | head -n 1)
        
        local archivo_final="${ruta_base}/${nombre_cepa}_${tipo}.fastq"

        # Si hay gz y no hay fastq, descomprimimos
        if [ -n "$archivo_gz" ] && [ ! -f "$archivo_final" ]; then
            printf "Descomprimiendo %s: %s\n" "$tipo" "$(basename "$archivo_gz")"
            gunzip -c "$archivo_gz" > "$archivo_final"
        fi

        # Si tenemos el .fastq, ejecutamos FastQC si no existe el reporte
        if [ -f "$archivo_final" ]; then
            if [ ! -f "${archivo_final%.fastq}_fastqc.html" ]; then
                printf "Ejecutando FastQC en %s...\n" "$tipo"
                fastqc "$archivo_final"
            else
                printf "FastQC de %s ya existe. Saltando.\n" "$tipo"
            fi
        else
            printf "ADVERTENCIA: No se encontró %s para procesar.\n" "$tipo"
        fi
    }

    procesar_lectura "R1" "${NUEVA_RUTA}" "${nuevo_nombre}"
    procesar_lectura "R2" "${NUEVA_RUTA}" "${nuevo_nombre}"
    
    printf "_________________________________(Finished %s)____________________________\n\n" "${nuevo_nombre}"
done

echo "Proceso completo finalizado."