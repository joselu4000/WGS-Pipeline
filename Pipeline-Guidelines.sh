#!/bin/bash

set -o pipefail

# Directorio de trabajo
LOG_FILE="error.log"

# Limpiamos el log anterior para empezar de cero
echo "--- Iniciando nuevo Pipeline completo a las $(date) ---" > "$LOG_FILE"

# Función para manejar errores de forma centralizada
handle_error() {
    echo -e "\n\e[31m[ERROR] Fallo en $1 a las $(date)\e[0m" | tee -a "$LOG_FILE"
    echo "Revisa $LOG_FILE para ver los detalles."
    exit 1
}

###############################################################################
# COMPROBACIÓN PREVIA DE SALIDAS
###############################################################################

OUTPUT_DIRS=(
    "fastp"
    "fastq_trim"
    "tormes_output"
    "plasmid_output"
    "BLASTn-output"
)

EXISTING_OUTPUTS=()

for dir in "${OUTPUT_DIRS[@]}"; do
    if [ -e "$dir" ]; then
        EXISTING_OUTPUTS+=("$dir")
    fi
done

if [ "${#EXISTING_OUTPUTS[@]}" -gt 0 ]; then
    echo -e "\n\e[31m[ERROR] Se han detectado resultados de una ejecución anterior:\e[0m" | tee -a "$LOG_FILE"

    for dir in "${EXISTING_OUTPUTS[@]}"; do
        echo "  - $dir" | tee -a "$LOG_FILE"
    done

    echo ""
    echo "Mueve o elimina estas salidas antes de iniciar una ejecución completa."
    echo "El pipeline no borra resultados automáticamente."
    exit 1
fi

echo "Comprobación inicial superada: no existen salidas previas." | tee -a "$LOG_FILE"

# 1. Renombrar carpetas
echo -e "\n\e[34m--- PASO 1: Renombrando carpetas ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Rename-Correction.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Rename-Correction.sh"

# 2. Descomprimir archivos y primer FastQC
echo -e "\n\e[34m--- PASO 2: Descomprimiendo y primer FastQC ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Descomprime.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Descomprime.sh"

# 3. Limpieza con fastp
echo -e "\n\e[34m--- PASO 3: Ejecutando fastp ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Cleaning-fastp.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Cleaning-fastp.sh"

# 4. Trimado con prinseq-lite
echo -e "\n\e[34m--- PASO 4: Ejecutando Prinseq trimado ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Trimado-dobleOpt-q30.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Trimado-dobleOpt-q30.sh"

# 5. FastQC final
echo -e "\n\e[34m--- PASO 5: FastQC final ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/FastQC-trim.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "FastQC-trim.sh"

# Aviso y transición
echo -e "\n\e[32m==========================================================" | tee -a "$LOG_FILE"
echo -e "¡PASOS 1 AL 5 COMPLETADOS CON ÉXITO!" | tee -a "$LOG_FILE"
echo -e "==========================================================\e[0m\n" | tee -a "$LOG_FILE"

# Identificar carpetas vacías
CARPETAS_VACIAS=$(find fastq_trim/ -type d -empty)

if [ -n "$CARPETAS_VACIAS" ]; then
    echo -e "\e[33mSe han detectado las siguientes carpetas vacías:\e[0m"
    echo "$CARPETAS_VACIAS"

    read -p "¿Quieres borrar estas carpetas vacías? (s/n): " confirmacion

    if [[ "$confirmacion" == [sS] ]]; then
        find fastq_trim/ -type d -empty -print -delete
        echo "Carpetas eliminadas." | tee -a "$LOG_FILE"
    else
        echo "Saltando borrado de carpetas." | tee -a "$LOG_FILE"
    fi
else
    echo "No se encontraron carpetas vacías. Todo está limpio." | tee -a "$LOG_FILE"
fi

# 6. TORMES-subpipeline
echo -e "\n\e[34m--- PASO 6: Iniciando TORMES-subpipeline ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/TORMES-subpipeline.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "TORMES-subpipeline.sh"

# 7. Búsqueda de plásmidos
echo -e "\n\e[34m--- PASO 7: Ejecutando Plasmid-Finder ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Plasmid-Finder.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Plasmid-Finder.sh"

# 8. Unificar resultados de plásmidos
echo -e "\n\e[34m--- PASO 8: Generando tabla resumen de plásmidos ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/SumUP-plasmid.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "SumUP-plasmid.sh"

# 9. Búsqueda de genes de biofilm
echo -e "\n\e[34m--- PASO 9: Ejecutando BLASTn de Biofilm ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/BLASTn-Biofilm.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "BLASTn-Biofilm.sh"

# 10. Consolidar resultados de BLASTn
echo -e "\n\e[34m--- PASO 10: Generando tabla resumen de BLASTn ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/Sumup-BLASTn.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "Sumup-BLASTn.sh"

# 11. Búsqueda de genes truncados
echo -e "\n\e[34m--- PASO 11: Ejecutando BLASTn de Genes Truncados ---\e[0m" | tee -a "$LOG_FILE"
bash Codes-sh/BLASTn-Truncated.sh 2>&1 | tee -a "$LOG_FILE" || handle_error "BLASTn-Truncated.sh"

# 12. Finalización
echo -e "\n\e[34m--- PASO 12: Finalizando Pipeline ---\e[0m" | tee -a "$LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo " PIPELINE COMPLETADO CORRECTAMENTE" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
