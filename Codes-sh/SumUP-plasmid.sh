#!/bin/bash

# --- CONFIGURACIÓN ---
INPUT_DIR="plasmid_output"
# Guardamos el resultado directamente dentro de la carpeta de plásmidos
OUTPUT_FILE="${INPUT_DIR}/summary_plasmids_final.tsv"

# ---------------------

echo "Generando tabla resumen en ${OUTPUT_FILE}..."

# 1. Buscar el archivo de referencia para la cabecera
FIRST_FILE=$(find "$INPUT_DIR" -name "results_tab.tsv" | head -n 1)

if [ -z "$FIRST_FILE" ]; then
    echo "Error: No se encontraron archivos 'results_tab.tsv' en $INPUT_DIR"
    exit 1
fi

# 2. Crear la cabecera del archivo final
HEADER=$(head -n 1 "$FIRST_FILE")
echo -e "Sample\t$HEADER" > "$OUTPUT_FILE"

# 3. Recorrer cada subcarpeta de muestra
for folder in "$INPUT_DIR"/*; do
    # Importante: Solo procesamos directorios (para evitar leer el propio summary si ya existe)
    [ -d "$folder" ] || continue
    
    SAMPLE_NAME=$(basename "$folder")
    RESULT_FILE="${folder}/results_tab.tsv"

    if [ -f "$RESULT_FILE" ]; then
        # Extraer datos saltando cabecera y añadir nombre de muestra
        tail -n +2 "$RESULT_FILE" | awk -v sample="$SAMPLE_NAME" 'BEGIN{FS=OFS="\t"} {print sample OFS $0}' >> "$OUTPUT_FILE"
    fi
done

echo "¡Hecho! El resumen se ha guardado en: $OUTPUT_FILE"