#!/bin/bash

# --- CONFIGURACIÓN ---
#ARCHIVO_DATOS="Prova.txt"
ARCHIVO_DATOS="Strains-raw/IDs-Correspondences.txt"
DIR_INPUT="Strains-raw"
DIR_OUTPUT_BASE="fastp"  # Ahora fastp estará al mismo nivel que Strains-raw

# Parámetros fastp
QQ=30
THREAD_COUNT=16
NAME="clean" 

# ---------------------

if [ ! -f "$ARCHIVO_DATOS" ]; then
    echo "Error: No se encuentra el archivo $ARCHIVO_DATOS"
    exit 1
fi

# Crear la carpeta base de fastp si no existe
mkdir -p "$DIR_OUTPUT_BASE"

echo "Iniciando fastp con estructura paralela..."

tail -n +2 "$ARCHIVO_DATOS" | tr -d '\r' | while read -r nuevo_id nombre_original resto; do
    
    [ -z "$nuevo_id" ] && continue

    # Ruta de entrada (donde están los fastq descomprimidos)
    SAMPLE_INPUT_DIR="${DIR_INPUT}/${nuevo_id}"
    
    # Ruta de salida (dentro de la nueva carpeta fastp)
    SAMPLE_OUTPUT_DIR="${DIR_OUTPUT_BASE}/${nuevo_id}"
    
    printf "_________________________________(Start %s)____________________________\n" "${nuevo_id}"
    
    # 1. Comprobar si la carpeta de entrada existe
    if [ ! -d "${SAMPLE_INPUT_DIR}" ]; then
        printf "ERROR: No existe la carpeta de entrada %s. Saltando.\n" "${SAMPLE_INPUT_DIR}"
        continue
    fi
    
    # 2. Crear la subcarpeta de la muestra en fastp/
    mkdir -p "${SAMPLE_OUTPUT_DIR}"

    # 3. Definir archivos de entrada (los .fastq creados anteriormente)
    R1_INPUT="${SAMPLE_INPUT_DIR}/${nuevo_id}_R1.fastq"
    R2_INPUT="${SAMPLE_INPUT_DIR}/${nuevo_id}_R2.fastq"

    # 4. Definir rutas de salida (dentro de fastp/L1.305/...)
    R1_OUT="${SAMPLE_OUTPUT_DIR}/${nuevo_id}_R1_${NAME}.fastq.gz"
    R2_OUT="${SAMPLE_OUTPUT_DIR}/${nuevo_id}_R2_${NAME}.fastq.gz"
    HTML_REPORT="${SAMPLE_OUTPUT_DIR}/${nuevo_id}_${NAME}.html"
    JSON_REPORT="${SAMPLE_OUTPUT_DIR}/${nuevo_id}_${NAME}.json"
    
    # 5. Ejecución de fastp
    if [ -f "${R1_INPUT}" ] && [ -f "${R2_INPUT}" ]; then
        printf "Procesando: %s\n" "${nuevo_id}"
        
        fastp \
            -i "${R1_INPUT}" \
            -I "${R2_INPUT}" \
            -o "${R1_OUT}" \
            -O "${R2_OUT}" \
            --trim_poly_g \
            --trim_poly_x \
            --disable_length_filtering \
            --average_qual "${QQ}" \
            --n_base_limit 0 \
            --thread "${THREAD_COUNT}" \
            --html "${HTML_REPORT}" \
            --json "${JSON_REPORT}"
            
        printf "Éxito: Resultados en %s\n" "${SAMPLE_OUTPUT_DIR}"
    else
        printf "ADVERTENCIA: No se hallaron archivos .fastq en %s\n" "${SAMPLE_INPUT_DIR}"
    fi

    printf "_________________________________(Finished %s)____________________________\n\n" "${nuevo_id}"
    
done

echo "Proceso finalizado. Estructura 'fastp/' creada con éxito."