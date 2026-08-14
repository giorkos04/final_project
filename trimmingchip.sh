#!/bin/bash
set -ey

# Directories
RAW_DATA_DIR="/home/bio3815/final_project/chip_seq/chipseq_data"
TRIMMED_DIR="/home/bio3815/final_project/chip_seq/trimmed_chip"
QC_DIR="/home/bio3815/final_project/chip_seq/fastp_qc"
LOG_DIR="/home/bio3815/final_project/chip_seq/logs"

# Create output directories
echo "Creating output directories..."
mkdir -p "${TRIMMED_DIR}" "${QC_DIR}" "${LOG_DIR}"

# Fastp parameters
THREADS=2   # Increased to 2 as most servers can handle this easily
MIN_LENGTH=25
MIN_QUALITY=20

# Check raw data directory exists
if [ ! -d "${RAW_DATA_DIR}" ]; then
    echo "ERROR: Raw data directory not found: ${RAW_DATA_DIR}"
    exit 1
fi

cd "${RAW_DATA_DIR}"

# Check for single-end fastq files
if ! ls *.fastq.gz 1>/dev/null 2>&1; then
    echo "ERROR: No .fastq.gz files found in ${RAW_DATA_DIR}"
    exit 1
fi

# Extract sample names (removing .fastq.gz extension)
SAMPLES=$(ls *.fastq.gz | sed 's/.fastq.gz//' | sort -u)

# Count samples
SAMPLE_COUNT=$(echo "${SAMPLES}" | wc -w)
echo "Found ${SAMPLE_COUNT} samples to process"

# Process each sample
COUNTER=0
for SAMPLE in ${SAMPLES}; do
    COUNTER=$((COUNTER + 1))
    echo ""
    echo "Processing sample ${COUNTER}/${SAMPLE_COUNT}: ${SAMPLE}"

    # Define input and output files
    R_IN="${RAW_DATA_DIR}/${SAMPLE}.fastq.gz"
    R_OUT="${TRIMMED_DIR}/${SAMPLE}_trimmed.fastq.gz"

    # QC and log files
    HTML_REPORT="${QC_DIR}/${SAMPLE}_fastp.html"
    JSON_REPORT="${QC_DIR}/${SAMPLE}_fastp.json"
    LOG_FILE="${LOG_DIR}/${SAMPLE}_fastp.log"

    # Run fastp for Single-End
    # Note: Removed --detect_adapter_for_pe
    fastp \
        -i "${R_IN}" \
        -o "${R_OUT}" \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality ${MIN_QUALITY} \
        --length_required ${MIN_LENGTH} \
        --thread ${THREADS} \
        --html "${HTML_REPORT}" \
        --json "${JSON_REPORT}" \
        --report_title "${SAMPLE} fastp QC Report" \
        2>&1 | tee "${LOG_FILE}"

    echo "✓ Completed ${SAMPLE} (${COUNTER}/${SAMPLE_COUNT})"
done

echo ""
echo "All samples processed successfully."
