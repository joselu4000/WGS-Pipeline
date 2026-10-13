#!/bin/bash

set -euo pipefail

echo "============================================================"
echo " DATABASE SETUP"
echo "============================================================"

###############################################################################
# 1. Check required commands
###############################################################################

for cmd in makeblastdb git python kma_index; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd"
        echo "Activate the pipeline Conda environment before running this script."
        exit 1
    fi
done

###############################################################################
# 2. Build BLAST database for biofilm-associated genes
###############################################################################

BLAST_DIR="Codes-sh/BLASTn"
BLAST_FASTA="${BLAST_DIR}/BGRD_sequences.fasta"
BLAST_DB="${BLAST_DIR}/genes_db"

if [ ! -f "$BLAST_FASTA" ]; then
    echo "[ERROR] Missing FASTA file: $BLAST_FASTA"
    exit 1
fi

echo ""
echo "--- Building BLAST database ---"

rm -f "${BLAST_DB}".*

makeblastdb \
    -in "$BLAST_FASTA" \
    -dbtype nucl \
    -out "$BLAST_DB"

echo "BLAST database created successfully."

###############################################################################
# 3. PlasmidFinder database
###############################################################################

DB_ROOT="databases"
PLASMID_DB="${DB_ROOT}/plasmidfinder_db"
PLASMID_DB_COMMIT="07648fddc4c6cf0330c9fc041dd6f52b4a69f8d6"

mkdir -p "$DB_ROOT"

if [ ! -d "${PLASMID_DB}/.git" ]; then
    echo ""
    echo "--- Downloading PlasmidFinder database ---"

    git clone \
        https://bitbucket.org/genomicepidemiology/plasmidfinder_db.git \
        "$PLASMID_DB"
else
    echo ""
    echo "PlasmidFinder database already present."
fi

echo ""
echo "--- Setting validated PlasmidFinder database version ---"

git -C "$PLASMID_DB" fetch --tags origin
git -C "$PLASMID_DB" checkout --detach "$PLASMID_DB_COMMIT"

echo "PlasmidFinder database commit:"
git -C "$PLASMID_DB" rev-parse HEAD

###############################################################################
# 4. Build KMA indexes for PlasmidFinder
###############################################################################

echo ""
echo "--- Building KMA indexes for PlasmidFinder ---"

(
    cd "$PLASMID_DB"
    python INSTALL.py kma_index
)

echo "PlasmidFinder KMA indexes created successfully."

echo ""
echo "============================================================"
echo " DATABASE SETUP COMPLETED"
echo "============================================================"
