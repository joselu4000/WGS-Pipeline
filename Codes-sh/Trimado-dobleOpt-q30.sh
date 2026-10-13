#!/bin/bash

# --- CONFIGURACIÓN ---
#ARCHIVO_DATOS="Prova.txt"
ARCHIVO_DATOS="Strains-raw/IDs-Correspondences.txt"
DIR_INPUT="fastp"        # Donde están los archivos de fastp
DIR_OUTPUT="fastq_trim"  # Nueva carpeta para prinseq

# Parámetros Prinseq
name="trim_q30"
II=20
DD=5

# ---------------------

if [ ! -f "$ARCHIVO_DATOS" ]; then
    echo "Error: No se encuentra el archivo $ARCHIVO_DATOS"
    exit 1
fi

mkdir -p "$DIR_OUTPUT"

echo "Iniciando recorte con Prinseq..."

tail -n +2 "$ARCHIVO_DATOS" | tr -d '\r' | while read -r nuevo_id resto; do
    
    [ -z "$nuevo_id" ] && continue

    echo "Processing ${nuevo_id}"
    
    # Rutas de carpetas
    SAMPLE_IN="${DIR_INPUT}/${nuevo_id}"
    SAMPLE_OUT="${DIR_OUTPUT}/${nuevo_id}"
    mkdir -p "$SAMPLE_OUT"

    # --- Procesamiento R1 ---
    FILE_R1_GZ="${SAMPLE_IN}/${nuevo_id}_R1_clean.fastq.gz"
    FILE_R1_TMP="${SAMPLE_IN}/${nuevo_id}_R1_clean.fastq"

    if [ -f "$FILE_R1_GZ" ]; then
        # Descomprimir temporalmente
        gunzip -c "$FILE_R1_GZ" > "$FILE_R1_TMP"
        
        perl prinseq-lite.pl \
            -trim_left $II \
            -trim_right $DD \
            -fastq "$FILE_R1_TMP" \
            -out_format 3 \
            -out_good "${SAMPLE_OUT}/${nuevo_id}_R1_$name" \
            -out_bad null
        
        # Borrar el temporal para no llenar el disco
        rm "$FILE_R1_TMP"
    fi

    # --- Procesamiento R2 ---
    FILE_R2_GZ="${SAMPLE_IN}/${nuevo_id}_R2_clean.fastq.gz"
    FILE_R2_TMP="${SAMPLE_IN}/${nuevo_id}_R2_clean.fastq"

    if [ -f "$FILE_R2_GZ" ]; then
        # Descomprimir temporalmente
        gunzip -c "$FILE_R2_GZ" > "$FILE_R2_TMP"
        
        perl prinseq-lite.pl \
            -trim_left $II \
            -trim_right $DD \
            -fastq "$FILE_R2_TMP" \
            -out_format 3 \
            -out_good "${SAMPLE_OUT}/${nuevo_id}_R2_$name" \
            -out_bad null
        
        # Borrar el temporal
        rm "$FILE_R2_TMP"
    fi

done

echo "Proceso finalizado. Resultados en: $DIR_OUTPUT"