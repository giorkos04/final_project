#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable

# 1. DIRECTORIES - Verify these paths one more time!
TRIMMED_DIR="/home/bio3815/final_project/trimmed"
ALIGN_DIR="/home/bio3815/final_project/aligned"
COUNTS_DIR="/home/bio3815/final_project/counts"
LOG_DIR="/home/bio3815/final_project/logs"

# STAR genome index 
GENOME_INDEX="/home/bio3815/final_project/star_index_mm39" 

# GTF annotation
GTF_FILE="/home/bio3815/final_project/gencode.vM38.annotation.gtf"

# 2. PERFORMANCE
# Since user 3958 is using 31 threads, I set this to 6.
# It is fast but won't crash the server.
THREADS=1 

# Create output directories
mkdir -p "${ALIGN_DIR}" "${COUNTS_DIR}" "${LOG_DIR}"

# Check genome index directory contains the actual index files
if [ ! -f "${GENOME_INDEX}/Genome" ]; then
    echo "ERROR: STAR index files (Genome) not found in ${GENOME_INDEX}"
    exit 1
fi

# Get sample list from the trimmed directory
cd "${TRIMMED_DIR}"
# This looks for files ending in _1_trimmed.fastq.gz and extracts the ID
SAMPLES=$(ls *_1_trimmed.fastq.gz | sed 's/_1_trimmed.fastq.gz//' | sort -u)

# Count samples
SAMPLE_COUNT=$(echo "${SAMPLES}" | wc -l)
echo "Found ${SAMPLE_COUNT} samples to align"

COUNTER=0
for SAMPLE in ${SAMPLES}; do
    COUNTER=$((COUNTER+1))
    echo "--------------------------------------------"
    echo "Processing sample ${COUNTER}/${SAMPLE_COUNT}: ${SAMPLE}"

    # 3. DEFINE VARIABLES (MUST happen before usage because of set -u)
    R1="${TRIMMED_DIR}/${SAMPLE}_1_trimmed.fastq.gz"
    R2="${TRIMMED_DIR}/${SAMPLE}_2_trimmed.fastq.gz"
    OUTPUT_PREFIX="${ALIGN_DIR}/${SAMPLE}_"
    BAM_FILE="${OUTPUT_PREFIX}Aligned.sortedByCoord.out.bam"

    # Check if input files actually exist
    if [ ! -f "${R1}" ] || [ ! -f "${R2}" ]; then
        echo "ERROR: Input files not found for ${SAMPLE}. Skipping."
        continue
    fi

    # Skip if already done
    if [ -f "${BAM_FILE}" ]; then
        echo "Sample ${SAMPLE} already aligned. Skipping to next."
        continue
    fi

    echo "Running STAR for ${SAMPLE}..."

    # 4. RUN STAR (Note the backslashes \ at the end of EVERY line)
    STAR \
        --runMode alignReads \
        --genomeDir "${GENOME_INDEX}" \
        --readFilesIn "${R1}" "${R2}" \
        --readFilesCommand zcat \
        --outFileNamePrefix "${OUTPUT_PREFIX}" \
        --runThreadN ${THREADS} \
        --outSAMtype BAM SortedByCoordinate \
        --outSAMunmapped Within \
        --outSAMattributes Standard \
        --quantMode GeneCounts \
        --sjdbGTFfile "${GTF_FILE}" \
        --twopassMode Basic \
        --outFilterMultimapNmax 40 \
        --seedSearchStartLmax 20 \
	--outFilterScoreMinOverLread 0.3 \
	--outFilterMatchNminOverLread 0.3 \ 
      --alignSJoverhangMin 1 \
        --outFilterMismatchNmax 999 \
        --outFilterMismatchNoverReadLmax 0.04 \
        --alignIntronMin 20 \
        --alignIntronMax 1000000 \
        --alignMatesGapMax 1000000 \
        --limitBAMsortRAM 30000000000

    echo "Finished alignment for ${SAMPLE}"
done

echo "ALL SAMPLES COMPLETED SUCCESSFULLY."


