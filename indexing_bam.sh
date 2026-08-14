#!/bin/bash
set -e  # Exit on error

# DIRECTORIES
TRIMMED_DIR="/home/bio3815/final_project/trimmed"
ALIGN_DIR="/home/bio3815/final_project/aligned"
LOG_DIR="/home/bio3815/final_project/logs"

THREADS=4

# Create log directory
mkdir -p "${LOG_DIR}"

# Get sample list
cd "${TRIMMED_DIR}"
SAMPLES=$(ls SRR*_1_trimmed.fastq.gz | sed 's/_1_trimmed.fastq.gz//' | sort -u)

# Count samples
SAMPLE_COUNT=$(echo "${SAMPLES}" | wc -w)
echo "Found ${SAMPLE_COUNT} BAM files to index"

COUNTER=0
for SAMPLE in ${SAMPLES}; do
    COUNTER=$((COUNTER+1))

    OUTPUT_PREFIX="${ALIGN_DIR}/${SAMPLE}_"
    BAM_FILE="${OUTPUT_PREFIX}Aligned.sortedByCoord.out.bam"
    BAI_FILE="${BAM_FILE}.bai"

    echo "--------------------------------------------"
    echo "Indexing sample ${COUNTER}/${SAMPLE_COUNT}: ${SAMPLE}"

    # Check BAM exists and has content
    if [ ! -f "${BAM_FILE}" ] || [ ! -s "${BAM_FILE}" ]; then
        echo "WARNING: BAM file missing or empty for ${SAMPLE} - skipping"
        continue
    fi

    # Skip if already indexed
    if [ -f "${BAI_FILE}" ]; then
        echo "${SAMPLE} already indexed - skipping"
        continue
    fi

    # Index BAM file
    samtools index -@ ${THREADS} "${BAM_FILE}"

    echo "✓ Indexed ${SAMPLE} (${COUNTER}/${SAMPLE_COUNT})"
done

echo ""
echo "All BAM files indexed."
echo "Index files (.bai) are in: ${ALIGN_DIR}"
