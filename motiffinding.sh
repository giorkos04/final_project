#!/bin/bash
set -e  # Exit on error


PEAKS_DIR="/home/bio3815/final_project/chip_seq/peaks"
MOTIFS_DIR="/home/bio3815/final_project/chip_seq/motifs"
LOG_DIR="/home/bio3815/final_project/chip_seq/logs_motifs"


GENOME="mm39"
# Reference genome for HOMER
# Must match the genome you used for alignment
# HOMER uses this to get background sequences for comparison



THREADS=1
mkdir -p "${MOTIFS_DIR}" "${LOG_DIR}"
echo "Output directories created"

# ============================================================
# CHECK HOMER IS INSTALLED
# ============================================================
if ! command -v findMotifsGenome.pl &> /dev/null; then
    echo "ERROR: HOMER not found"
    echo "Install with: conda install -c bioconda homer"
    exit 1
fi
echo "HOMER found - proceeding"

# ============================================================
# CHECK GENOME IS INSTALLED IN HOMER
# ============================================================


echo "HOMER genome ${GENOME} found - proceeding"

# ============================================================
# DEFINE PEAK FILES TO ANALYZE
# ============================================================
GAINED_PEAKS="${PEAKS_DIR}/gained_peaks_fixed.bed"
# Peaks with more H3K27ac in old liver
# From DiffBind: Fold > 0

LOST_PEAKS="${PEAKS_DIR}/lost_peaks_fixed.bed"
# Peaks with less H3K27ac in old liver
# From DiffBind: Fold < 0

# ============================================================
# CHECK PEAK FILES EXIST
# ============================================================
for PEAK_FILE in "${GAINED_PEAKS}" "${LOST_PEAKS}"; do
    if [ ! -f "${PEAK_FILE}" ] || [ ! -s "${PEAK_FILE}" ]; then
        echo "ERROR: Peak file missing or empty: ${PEAK_FILE}"
        echo "Run DiffBind first to generate gained and lost peak files"
        exit 1
    fi
done

echo "Peak files found:"
echo "  Gained peaks: $(wc -l < ${GAINED_PEAKS}) peaks"
echo "  Lost peaks:   $(wc -l < ${LOST_PEAKS}) peaks"

# ============================================================
# DEFINE OUTPUT DIRECTORIES FOR EACH ANALYSIS
# ============================================================
GAINED_MOTIFS_DIR="${MOTIFS_DIR}/gained_motifs"
# HOMER output folder for gained peaks
# Will contain knownResults.html and homerResults.html

LOST_MOTIFS_DIR="${MOTIFS_DIR}/lost_motifs"
# HOMER output folder for lost peaks

# ============================================================
# PROCESS EACH PEAK SET
# ============================================================
COUNTER=0
TOTAL=2

for ANALYSIS in "gained" "lost"; do
    COUNTER=$((COUNTER + 1))
    echo "--------------------------------------------"
    echo "Running motif analysis ${COUNTER}/${TOTAL}: ${ANALYSIS} peaks"

    # Select correct input and output for this analysis
    if [ "${ANALYSIS}" = "gained" ]; then
        PEAK_FILE="${GAINED_PEAKS}"
        OUTPUT_DIR="${GAINED_MOTIFS_DIR}"
    else
        PEAK_FILE="${LOST_PEAKS}"
        OUTPUT_DIR="${LOST_MOTIFS_DIR}"
    fi

    LOG="${LOG_DIR}/${ANALYSIS}_homer.log"

    # Check if already done
    if [ -f "${OUTPUT_DIR}/knownResults.html" ]; then
        echo "${ANALYSIS} motifs already analyzed - skipping"
        continue
    fi

    # Create output directory for this analysis
    mkdir -p "${OUTPUT_DIR}"

    # Run HOMER findMotifsGenome
    echo "Running HOMER findMotifsGenome for ${ANALYSIS} peaks..."
    findMotifsGenome.pl \
    "${PEAK_FILE}" \
    "${GENOME}" \
    "${OUTPUT_DIR}" \
    -size 200 \
    -mask \
    -p "${THREADS}" \
    2>&1 | tee "${LOG}"

    # Check output was created
    if [ -f "${OUTPUT_DIR}/knownResults.html" ]; then
        echo "✓ Motif analysis complete for ${ANALYSIS} peaks"
        echo "  Results: ${OUTPUT_DIR}/knownResults.html"
    else
        echo "WARNING: HOMER output not found for ${ANALYSIS}"
        echo "Check log: ${LOG}"
    fi

done

# ============================================================
# FINAL SUMMARY
# ============================================================
echo ""
echo "============================================"
echo "MOTIF ANALYSIS COMPLETE"
echo "============================================"
echo ""
echo "Results:"
echo "  Gained motifs: ${GAINED_MOTIFS_DIR}/knownResults.html"
echo "  Lost motifs:   ${LOST_MOTIFS_DIR}/knownResults.html"
