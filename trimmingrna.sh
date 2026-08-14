#!/bin/bash
set -ey

# Directories
RAW_DATA_DIR="/home/bio3815/final_project/rnaseq_data"
TRIMMED_DIR="/home/bio3815/final_project/trimmed"
QC_DIR="/home/bio3815/final_project/fastp_qc"
LOG_DIR="/home/bio3815/final_project/logs"

# Create output directories
echo "Creating output directories..."
mkdir -p "${TRIMMED_DIR}" "${QC_DIR}" "${LOG_DIR}"

# Fastp parameters
THREADS=2   
MIN_LENGTH=25
MIN_QUALITY=20

# Check raw data directory exists
if [ ! -d "${RAW_DATA_DIR}" ]; then
    echo "ERROR: Raw data directory not found: ${RAW_DATA_DIR}"
    exit 1
fi

cd "${RAW_DATA_DIR}"

# Check files exist before extracting sample names
if ! ls SRR*_1.fastq.gz 1>/dev/null 2>&1; then
    echo "ERROR: No files matching SRR*_1.fastq.gz found in ${RAW_DATA_DIR}"
    echo "Files present:"
    ls -lh
    exit 1
fi

# Extract sample names
SAMPLES=$(ls SRR*_1.fastq.gz | sed 's/_1\.fastq\.gz//' | sort -u)

# Count samples
SAMPLE_COUNT=$(echo "${SAMPLES}" | wc -w)
echo "Found ${SAMPLE_COUNT} samples to process"

# Process each sample
COUNTER=0
for SAMPLE in ${SAMPLES}; do
    COUNTER=$((COUNTER + 1))
    echo ""
    echo "Processing sample ${COUNTER}/${SAMPLE_COUNT}: ${SAMPLE}"

    # Define input files
    R1="${RAW_DATA_DIR}/${SAMPLE}_1.fastq.gz"
    R2="${RAW_DATA_DIR}/${SAMPLE}_2.fastq.gz"

    # Define output files
    R1_TRIMMED="${TRIMMED_DIR}/${SAMPLE}_1_trimmed.fastq.gz"
    R2_TRIMMED="${TRIMMED_DIR}/${SAMPLE}_2_trimmed.fastq.gz"

    # QC and log files
    HTML_REPORT="${LOG_DIR}/${SAMPLE}_fastp.html"
    JSON_REPORT="${QC_DIR}/${SAMPLE}_fastp.json"
    LOG_FILE="${LOG_DIR}/${SAMPLE}_fastp.log"

    # Check input files exist
    if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
        echo "ERROR: Input files not found for ${SAMPLE}"
        echo "  Expected R1: ${R1}"
        echo "  Expected R2: ${R2}"
        continue
    fi

    # Run fastp
    fastp \
        -i "${R1}" \
        -I "${R2}" \
        -o "${R1_TRIMMED}" \
        -O "${R2_TRIMMED}" \
        --detect_adapter_for_pe \
        --cut_front \
        --cut_tail \
        --cut_window_size 4 \
        --cut_mean_quality ${MIN_QUALITY} \
        --qualified_quality_phred ${MIN_QUALITY} \
        --unqualified_percent_limit 40 \
        --length_required ${MIN_LENGTH} \
        --thread ${THREADS} \
        --html "${HTML_REPORT}" \
        --json "${JSON_REPORT}" \
        --report_title "${SAMPLE} fastp QC Report" \
        2>&1 | tee "${LOG_FILE}"

    echo "✓ Completed ${SAMPLE} (${COUNTER}/${SAMPLE_COUNT})"
done

echo ""
echo "All samples processed."
echo "Trimmed files: ${TRIMMED_DIR}"
echo "QC reports:    ${QC_DIR}"
echo "Logs:          ${LOG_DIR}"     
