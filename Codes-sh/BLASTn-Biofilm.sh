#!/bin/bash

# 1. Detectar ubicación del script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# --- CONFIGURACIÓN ---
INPUT_DIR="${SCRIPT_DIR}/../tormes_output/genomes"
DB_PATH="${SCRIPT_DIR}/BLASTn/genes_db"
GENES_LIST="${SCRIPT_DIR}/BLASTn/biofilm_G.txt"
CLEAN_GENES="${SCRIPT_DIR}/BLASTn/genes_limpios.txt"
OUT_DIR="${SCRIPT_DIR}/../BLASTn-output"
# ---------------------

mkdir -p "$OUT_DIR"

# 2. Preparar lista de genes para el filtrado final
if [ -f "$GENES_LIST" ]; then
    echo "Preparando lista de genes..."
    tail -n +2 "$GENES_LIST" | \
    cut -f2 | \
    tr -d '\r' | \
    awk 'NF {print tolower($1)}' | \
    sort -u > "$CLEAN_GENES"
else
    echo "Error: No se encuentra $GENES_LIST"
    exit 1
fi

echo "Iniciando BLASTn (Extracción directa de anotaciones)..."

# 3. Bucle de procesamiento
for fasta_file in "$INPUT_DIR"/L1.*.fasta; do
    [ -e "$fasta_file" ] || continue
    cepa=$(basename "$fasta_file" .fasta)

    echo "--------------------------------------------------------"
    echo "Procesando muestra: $cepa"

    # Archivos de salida
    blast_out_raw="${OUT_DIR}/${cepa}_blast_full.tsv"
    filtered_csv="${OUT_DIR}/${cepa}_blast_filtrado.csv"

    # 4. Ejecutar blastn EXTRAYENDO EL TÍTULO (stitle)
    # El campo 'stitle' contiene los [gene=...], [protein=...] que buscabas en el .fna
    blastn -query "$fasta_file" -db "$DB_PATH" -out "$blast_out_raw" \
    -outfmt "6 qseqid sseqid stitle pident length mismatch gapopen qstart qend sstart send evalue bitscore"

    # 5. Formatear y Filtrar directamente con AWK (Simula lo que hacía el Python)
    # Convertimos el formato de BLAST (puntos/tabs) a CSV y filtramos por tu lista de genes
    # La columna 3 ($3) ahora contiene toda la descripción del gen.
    
    # Escribir cabecera en el archivo filtrado
    echo "qseqid,sseqid,full_annotation,pident,length,mismatch,gapopen,qstart,qend,sstart,send,evalue,bitscore" > "$filtered_csv"

    awk -F'\t' -v OFS=',' '
	NR==FNR {
	    genes[tolower($1)] = 1
	    next
	}
	{
	    annotation = tolower($3)
	    locus = ""

	    if (match(annotation, /\[locus_tag=[^]]+\]/)) {
		locus = substr(annotation, RSTART, RLENGTH)
		sub(/^\[locus_tag=/, "", locus)
		sub(/\]$/, "", locus)
	    }

	    if (locus in genes) {
		print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13
	    }
	}' "$CLEAN_GENES" "$blast_out_raw" >> "$filtered_csv"

    echo "Finalizado $cepa"
done

echo "--------------------------------------------------------"
echo "Proceso completado. Resultados en BLASTn-output/"
