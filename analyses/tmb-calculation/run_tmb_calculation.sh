#!/bin/bash
# OPenPedCan 2021
# Eric Wafula
set -e
set -o pipefail

# This script should always run as if it were being called from
# the directory it lives in.
script_directory="$(perl -e 'use File::Basename;
 use Cwd "abs_path";
 print dirname(abs_path(@ARGV[0]));' -- "$0")"
cd "$script_directory" || exit

# Set up paths to data files consumed by analysis
data_path="../../data"
scratch_path="../../scratch"
bed_files_path="input"

# BED and GTF file paths
cds_file="${scratch_path}/gencode.v27.primary_assembly.annotation.bed"
wgs_bed="${scratch_path}/intersect_strelka_mutect2_vardict_WGS.bed"

# Filtered Fusion file 
variant_file="${data_path}/snv-consensus-plus-hotspots.maf.tsv.gz"

# sample to BED mapping file
mapping_file="${bed_files_path}/biospecimen_id_to_bed_map.txt"

# Histology file
histology_file="${data_path}/histologies.tsv"


############# Create intersection BED files for TMB calculations ###############
# Make All mutations BED files
bedtools intersect \
  -a ${bed_files_path}/hg38_strelka.bed \
  -b ${bed_files_path}/wgs_canonical_calling_regions.hg38.bed \
  > $wgs_bed

#################### Make coding regions file
# Convert GTF to BED file for use in bedtools
# Here we are only extracting lines with as a CDS i.e. are coded in protein
gunzip -c ${data_path}/gencode.v27.primary_assembly.annotation.gtf.gz \
  | awk '$3 ~ /CDS/' \
  | convert2bed --do-not-sort --input=gtf - \
  | sort -k 1,1 -k 2,2n \
  | bedtools merge  \
  > $cds_file

######################### Calculate consensus TMB ##############################
Rscript 01-calculate_tmb.R \
  --consensus_maf_file $variant_file \
  --bed_files $mapping_file \
  --histologies_file $histology_file \
  --coding_regions $cds_file \
  --nonsynfilter_maf
