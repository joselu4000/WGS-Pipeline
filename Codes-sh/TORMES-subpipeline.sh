#!/bin/bash

# 1. Limpiar el archivo original de caracteres Windows (\r)
sed 's/\r//g' Strains-raw/METADATA.txt > METADATA_TMP.txt

# 2. Ruta base absoluta
BASE_DIR=$(pwd)

echo "--- FILTRANDO METADATA SEGÚN ARCHIVOS DISPONIBLES ---"

# 3. Generar metadata.txt filtrado
awk -v base="$BASE_DIR" -F'\t' 'BEGIN {OFS="\t"} 
NR==1 {
    # Guardamos los encabezados
    header = "Samples\tRead1\tRead2"
    for (i=2; i<=NF; i++) header = header "\t" $i
    print header
    next
} 
{ 
    id = $1; gsub(/[[:space:]]/, "", id);
    if (id == "") next;

    # Definimos la ruta esperada
    r1 = "fastq_trim/" id "/" id "_R1_trim_q30.fastq"
    r2 = "fastq_trim/" id "/" id "_R2_trim_q30.fastq"
    
    # SOLO si los dos archivos existen, procesamos esta línea
    if ((system("test -f " r1) == 0) && (system("test -f " r2) == 0)) {
        abs1 = base "/" r1
        abs2 = base "/" r2
        
        linea = id "\t" abs1 "\t" abs2
        for (i=2; i<=NF; i++) linea = linea "\t" $i
        print linea
    }
}' METADATA_TMP.txt > metadata.txt

# 4. Validación
total_encontradas=$(($(wc -l < metadata.txt) - 1))
echo "Muestras encontradas y listas para procesar: $total_encontradas"

if [ "$total_encontradas" -eq 0 ]; then
    echo "ERROR: No se encontró ninguna muestra coincidente en 'fastq_trim'."
    exit 1
fi

# 5. Ejecutar TORMES
echo "Iniciando TORMES..."
#rm -rf tormes_output
tormes -m metadata.txt -o tormes_output --min_len 100 #--skip-pangenome #--skip-report