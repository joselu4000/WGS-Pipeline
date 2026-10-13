#!/bin/bash

# --- RUTAS ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

INPUT_DIR="${PROJECT_DIR}/tormes_output/genomes"
OUTPUT_DIR="${PROJECT_DIR}/plasmid_output"
DB_DIR="${PROJECT_DIR}/databases/plasmidfinder_db"

mkdir -p "$OUTPUT_DIR"

# --- COMPROBACIONES ---
if ! command -v plasmidfinder.py >/dev/null 2>&1; then
    echo "ERROR: plasmidfinder.py no está disponible en el entorno activo."
    exit 1
fi

if [ ! -d "$DB_DIR" ] || [ ! -f "$DB_DIR/config" ]; then
    echo "ERROR: No se encuentra la base de datos de PlasmidFinder en:"
    echo "$DB_DIR"
    exit 1
fi

echo "Iniciando búsqueda de plásmidos con PlasmidFinder..."

FAILED=0
FOUND=0

for fasta in "$INPUT_DIR"/L1.*.fasta; do
    [ -e "$fasta" ] || continue

    FOUND=1
    base_name=$(basename "$fasta" .fasta)
    outdir="${OUTPUT_DIR}/${base_name}"

    printf "_________________________________(Sample: %s)____________________________\n" "$base_name"

    # Un análisis ya completado no se repite.
    if [ -f "$outdir/results_tab.tsv" ]; then
        echo "Resultado completo ya existente. Saltando: $base_name"
        continue
    fi

    # Elimina únicamente resultados incompletos de ejecuciones anteriores.
    if [ -d "$outdir" ]; then
        echo "Eliminando directorio incompleto: $outdir"
        rm -rf "$outdir"
    fi

    mkdir -p "$outdir"

    plasmidfinder.py \
        -i "$fasta" \
        -o "$outdir" \
        -p "$DB_DIR" \
        -x

    if [ $? -eq 0 ] && [ -f "$outdir/results_tab.tsv" ]; then
        echo "Finalizado con éxito: $base_name"
    else
        echo "ERROR en el procesamiento de $base_name"
        FAILED=1
    fi
done

if [ "$FOUND" -eq 0 ]; then
    echo "ERROR: No se encontraron genomas L1.*.fasta en $INPUT_DIR"
    exit 1
fi

if [ "$FAILED" -ne 0 ]; then
    echo "ERROR: Una o más muestras fallaron en PlasmidFinder."
    exit 1
fi

echo "Proceso de búsqueda de plásmidos finalizado correctamente."
