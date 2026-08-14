#!/bin/bash
set -e

# DIRECTORIES
ALIGN_DIR="/home/bio3815/final_project/chip_seq/aligned_chip"
PEAKS_DIR="/home/bio3815/final_project/chip_seq/peaks_chip"
LOG_DIR="/home/bio3815/final_project/chip_seq/logs_peaks"
PAIRS_FILE="/home/bio3815/final_project/chip_seq/samples.pairs"

# Create directories
mkdir -p "${PEAKS_DIR}" "${LOG_DIR}"

# Check pairs file exists
if [ ! -f "${PAIRS_FILE}" ]; then
    echo "ERROR: Pairs file not found at: ${PAIRS_FILE}"
    exit 1
fi

TOTAL=$(wc -l < "${PAIRS_FILE}")
echo "Found ${TOTAL} pairs to process"
COUNTER=0

while read -r TREATMENT CONTROL; do
    COUNTER=$((COUNTER + 1))
    echo "--------------------------------------------"
    echo "Processing ${COUNTER}/${TOTAL}: ${TREATMENT} vs ${CONTROL}"

    # Define BAM paths
    T_BAM="${ALIGN_DIR}/${TREATMENT}_sorted.bam"
    C_BAM="${ALIGN_DIR}/${CONTROL}_sorted.bam"

    # Check BAM files exist and have content
    if [ ! -f "${T_BAM}" ] || [ ! -s "${T_BAM}" ]; then
        echo "ERROR: Treatment BAM missing or empty: ${T_BAM}"
        continue
    fi
    if [ ! -f "${C_BAM}" ] || [ ! -s "${C_BAM}" ]; then
        echo "ERROR: Control BAM missing or empty: ${C_BAM}"
        continue
    fi

    # Skip if already processed
    PEAK_FILE="${PEAKS_DIR}/${TREATMENT}_vs_${CONTROL}_peaks.broadPeak1"
    if [ -f "${PEAK_FILE}" ]; then
        echo "${TREATMENT} already processed - skipping"
        continue
    fi

    # Run MACS2
    macs2 callpeak \
        -t "${T_BAM}" \
        -c "${C_BAM}" \
        -f BAM \
        -g mm \
        -n "${TREATMENT}_vs_${CONTROL}" \
        --outdir "${PEAKS_DIR}" \
        --broad \
        --broad-cutoff 0.1 \
        -B \
        2> "${LOG_DIR}/${TREATMENT}_macs2.log"

    # Confirm output was created
    if [ -f "${PEAK_FILE}" ]; then
        PEAK_COUNT=$(wc -l < "${PEAK_FILE}")
        echo "✓ Done: ${TREATMENT} — ${PEAK_COUNT} peaks called"
    else
        echo "WARNING: Peak file not created for ${TREATMENT}"
    fi

done < "${PAIRS_FILE}"

echo ""
echo "Peak calling finished."
echo "Peaks:  ${PEAKS_DIR}"
echo "Logs:   ${LOG_DIR}"
