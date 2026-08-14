#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable

# 1. DIRECTORIES - Verify these paths one more time!
PEAKS_DIR="/home/bio3815/final_project/chip_seq/peaks"
ANNOT_DIR="/home/bio3815/final_project/chip_seq/annotated_peaks"
LOG_DIR="/home/bio3815/final_project/chip_seq/logs_annot"

# Genome for HOMER (mm39)
GENOME="mm39"

#GTF annotations
GTF_FILE="/home/bio3815/final_project/gencode.vM38.annotation.gtf"
# Create output directories
mkdir -p "${ANNOT_DIR}" "${LOG_DIR}"

# Peak files to annotate
PEAK_FILES=("gained_peaks_fixed.bed" "lost_peaks_fixed.bed")

for PEAK_FILE in "${PEAK_FILES[@]}"; do

    BASENAME=$(basename "${PEAK_FILE}" .bed)

    INPUT="${PEAKS_DIR}/${PEAK_FILE}"
    OUTPUT="${ANNOT_DIR}/${BASENAME}_annotated.txt"
    LOG="${LOG_DIR}/${BASENAME}_homer.log"

    # Check if input file exists
    if [ ! -f "${INPUT}" ]; then
        echo "ERROR: Input file not found: ${INPUT}. Skipping."
        continue
    fi

    # Skip if already done
    if [ -f "${OUTPUT}" ]; then
        echo "${PEAK_FILE} already annotated. Skipping."
        continue
    fi

    echo "Running HOMER annotatePeaks for ${PEAK_FILE}..."

    annotatePeaks.pl \
        "${INPUT}" \
        "${GENOME}" \
	-gtf "${GTF_FILE}" \
        > "${OUTPUT}" \
        2> "${LOG}"

    echo "Finished annotation for ${PEAK_FILE}"

done

echo "ALL SAMPLES COMPLETED SUCCESSFULLY."

