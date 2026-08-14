#!/bin/bash
set -e  # Exit on error

# DIRECTORIES
TRIMMED_DIR="/home/bio3815/final_project/chip_seq/trimmed_chip"
ALIGN_DIR="/home/bio3815/final_project/chip_seq/aligned_chip"
LOG_DIR="/home/bio3815/final_project/chip_seq/logs_chip"

# BWA genome index
BWA_INDEX="/home/bio3815/final_project/chip_seq/chip/mm39.fa"

THREADS=1

# Create output directories
mkdir -p "${ALIGN_DIR}" "${LOG_DIR}"

# Check genome index exists
if [ ! -f "${BWA_INDEX}.amb" ]; then
    echo "ERROR: BWA index not found at: ${BWA_INDEX}"
    echo "Expected files: ${BWA_INDEX}.amb .ann .bwt .pac .sa"
    exit 1
fi

# Check trimmed directory exists
if [ ! -d "${TRIMMED_DIR}" ]; then
    echo "ERROR: Trimmed directory not found: ${TRIMMED_DIR}"
    exit 1
fi

# Count samples
SAMPLE_COUNT=$(ls "${TRIMMED_DIR}"/*_trimmed.fastq.gz 2>/dev/null | wc -l)
if [ "${SAMPLE_COUNT}" -eq 0 ]; then
    echo "ERROR: No trimmed fastq.gz files found in ${TRIMMED_DIR}"
    exit 1
fi
echo "Found ${SAMPLE_COUNT} samples to align"

COUNTER=0

# Loop over single-end trimmed files
for SAMPLE in "${TRIMMED_DIR}"/*_trimmed.fastq.gz; do

    COUNTER=$((COUNTER + 1))
    BASENAME=$(basename "${SAMPLE}" _trimmed.fastq.gz)

    echo "--------------------------------------------"
    echo "Aligning sample ${COUNTER}/${SAMPLE_COUNT}: ${BASENAME}"

    # Define output files
    SAM="${ALIGN_DIR}/${BASENAME}.sam"
    BAM="${ALIGN_DIR}/${BASENAME}.bam"
    SORTED_BAM="${ALIGN_DIR}/${BASENAME}_sorted.bam"
    LOG="${LOG_DIR}/${BASENAME}_bwa.log"

    # Check input file exists
    if [ ! -f "${SAMPLE}" ]; then
        echo "ERROR: Input file not found: ${SAMPLE}. Skipping."
        continue
    fi

    # Skip if already successfully aligned
    if [ -f "${SORTED_BAM}" ] && [ -s "${SORTED_BAM}" ]; then
        echo "${BASENAME} already aligned - skipping."
        continue
    fi

    # Run BWA MEM (single-end - only one input file)
    echo "Running BWA MEM..."
    bwa mem \
        -t ${THREADS} \
        -M \
        "${BWA_INDEX}" \
        "${SAMPLE}" \
        > "${SAM}" \
        2> "${LOG}"

    # Convert SAM to BAM
    echo "Converting SAM to BAM..."
    samtools view \
        -bS \
        -@ ${THREADS} \
        "${SAM}" \
        -o "${BAM}"

    # Sort BAM
    echo "Sorting BAM..."
    samtools sort \
        -@ ${THREADS} \
        "${BAM}" \
        -o "${SORTED_BAM}"

    # Index sorted BAM
    echo "Indexing BAM..."
    samtools index "${SORTED_BAM}"

    # Remove intermediate SAM and unsorted BAM to save disk space
    rm -f "${SAM}" "${BAM}"

    # Check output exists and has content
    if [ -f "${SORTED_BAM}" ] && [ -s "${SORTED_BAM}" ]; then
        echo "✓ Completed ${BASENAME} (${COUNTER}/${SAMPLE_COUNT})"
    else
        echo "ERROR: Output BAM missing or empty for ${BASENAME}"
    fi

done

echo ""
echo "All samples processed."
echo "BAM files: ${ALIGN_DIR}"
echo "Logs:      ${LOG_DIR}"
q
