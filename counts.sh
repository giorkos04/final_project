#!/bin/bash
 featureCounts \
	-p \
	-M \
	-s 1 \
	-t exon \
	-g gene_id \
	-a refGene.gtf \
	-o counts.txt1 \
	 aligned/*bam
