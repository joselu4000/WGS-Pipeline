#!/bin/bash

# --- CONFIGURACIÓN ---
#ARCHIVO_DATOS="Prova.txt"
ARCHIVO_DATOS="Strains-raw/IDs-Correspondences.txt"
DIR_TRIM="fastq_trim"  # Directorio donde están los archivos de Prinseq
NAME="trim_q30"        # El sufijo que definimos en el script anterior

# ---------------------

if [ ! -f "$ARCHIVO_DATOS" ]; then
    echo "Error: No se encuentra el archivo $ARCHIVO_DATOS"
    exit 1
fi

echo "Iniciando FastQC sobre los datos trimados..."

# Leemos el archivo, limpiamos \r y saltamos la cabecera
tail -n +2 "$ARCHIVO_DATOS" | tr -d '\r' | while read -r nuevo_id resto; do
    
    [ -z "$nuevo_id" ] && continue

    SAMPLE_DIR="${DIR_TRIM}/${nuevo_id}"
    
    # 1. Comprobar si existe el directorio de la muestra
    if [ ! -d "${SAMPLE_DIR}" ]; then
        echo "Aviso: No se encontró el directorio ${SAMPLE_DIR}. Saltando..."
        continue
    fi

    # Entramos al directorio para ejecutar FastQC localmente (como en tu script original)
    cd "${SAMPLE_DIR}" || continue

    printf "_________________________________(Sample: %s)____________________________\n" "${nuevo_id}"

    # 2. Definir nombres de los archivos basados en el ID y el sufijo
    R1_FILE="${nuevo_id}_R1_${NAME}.fastq"
    R2_FILE="${nuevo_id}_R2_${NAME}.fastq"

    # 3. Ejecutar FastQC si los archivos existen
    if [ -f "$R1_FILE" ]; then
        printf "Ejecutando FastQC en R1: %s\n" "$R1_FILE"
        fastqc "$R1_FILE"
    else
        printf "ERROR: No se encontró %s\n" "$R1_FILE"
    fi

    if [ -f "$R2_FILE" ]; then
        printf "Ejecutando FastQC en R2: %s\n" "$R2_FILE"
        fastqc "$R2_FILE"
    else
        printf "ERROR: No se encontró %s\n" "$R2_FILE"
    fi

    # Volvemos al directorio base para la siguiente iteración
    cd - > /dev/null

done

echo "Proceso FastQC post-trimado finalizado."