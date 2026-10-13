#!/bin/bash

# 1. Detectar ubicación del script y definir rutas
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INPUT_DIR="${SCRIPT_DIR}/../BLASTn-output"
OUTPUT_FILE="${INPUT_DIR}/all_samples_blast_summary.csv"

echo "Iniciando la unión de resultados de BLASTn..."

# 2. Buscar el primer archivo para extraer la cabecera
FIRST_FILE=$(ls "$INPUT_DIR"/*_blast_filtrado.csv 2>/dev/null | head -n 1)

if [[ -z "$FIRST_FILE" ]]; then
    echo "Error: No se encontraron archivos *_blast_filtrado.csv en $INPUT_DIR"
    exit 1
fi

# 3. Crear el archivo final con la cabecera (añadiendo la columna Sample)
# Tomamos la primera línea del primer archivo y le ponemos "Sample," delante
head -n 1 "$FIRST_FILE" | awk '{print "Sample," $0}' > "$OUTPUT_FILE"

# 4. Iterar sobre todos los archivos filtrados
for file in "$INPUT_DIR"/*_blast_filtrado.csv; do
    # Saltamos el archivo de salida si ya existía para no duplicar datos
    [ "$file" == "$OUTPUT_FILE" ] && continue
    
    # Extraer el nombre de la muestra del nombre del archivo
    # (Ejemplo: de L1.X4_blast_filtrado.csv extrae L1.X4)
    SAMPLE_NAME=$(basename "$file" _blast_filtrado.csv)
    
    echo "  -> Uniendo muestra: $SAMPLE_NAME"
    
    # Tomar el contenido (saltando la cabecera con tail) y añadir el nombre de la muestra
    tail -n +2 "$file" | awk -v s="$SAMPLE_NAME" 'BEGIN{FS=OFS=","} {print s,$0}' >> "$OUTPUT_FILE"
done

echo "--------------------------------------------------------"
echo "¡Hecho! Tabla maestra creada en: $OUTPUT_FILE"