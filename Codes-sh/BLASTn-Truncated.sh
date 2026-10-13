#!/bin/bash

# 1. Rutas
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
INPUT_DIR="${SCRIPT_DIR}/../tormes_output/genomes"
QUERY_FASTA="${SCRIPT_DIR}/BLASTn/truncados.fasta"
OUT_DIR="${SCRIPT_DIR}/../BLASTn-output"
OUTPUT_FILE="${OUT_DIR}/all_samples_truncados_summary.csv"

mkdir -p "$OUT_DIR"

# 2. CREAR BASE DE DATOS DE LOS GENES
# Usamos -parse_seqids para que intente mantener los IDs originales
TMP_DB="${SCRIPT_DIR}/BLASTn/tmp_truncados_db"
echo "Preparando base de datos de consulta..."
makeblastdb -in "$QUERY_FASTA" -dbtype nucl -out "$TMP_DB" -parse_seqids > /dev/null

echo "Iniciando BLASTn de genes truncados..."

# 3. Cabecera del CSV
echo "Sample,gene_name,contig_id,pident,length,mismatch,gapopen,qstart,qend,sstart,send,evalue,bitscore" > "$OUTPUT_FILE"

# 4. Bucle
for fasta_file in "$INPUT_DIR"/L1.*.fasta; do
    [ -e "$fasta_file" ] || continue
    cepa=$(basename "$fasta_file" .fasta)

    echo "  -> Analizando genoma: $cepa"

    # EXPLICACIÓN DEL CAMBIO:
    # - Usamos 'stitle' en el outfmt: esto toma TODA la cabecera del gen en la DB.
    # - El genoma es el 'query' y los genes truncados son la 'db'.
    # - El AWK usa -F'\t' (tabulador) para evitar que espacios en el nombre del gen separen columnas.
    
    blastn -query "$fasta_file" -db "$TMP_DB" \
           -word_size 7 -reward 1 -penalty -1 -gapopen 2 -gapextend 1 \
           -outfmt "6 stitle qseqid pident length mismatch gapopen sstart send qstart qend evalue bitscore" | \
    awk -F'\t' -v s="$cepa" 'BEGIN{OFS=","} {
        # Limpiamos posibles comas en el nombre del gen para no romper el formato CSV
        gsub(",", " ", $1); 
        # Imprimimos: Muestra, NombreGen(stitle), Contig(qseqid), ...resto
        print s,$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12
    }' >> "$OUTPUT_FILE"

done

# Limpieza de archivos temporales
rm ${TMP_DB}.n*

echo "--------------------------------------------------------"
echo "¡Completado! Ahora la columna 'gene_name' debe contener el nombre completo del FASTA."