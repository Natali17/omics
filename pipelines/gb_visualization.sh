#!/bin/bash

# download wigToBigWig
wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/wigToBigWig

# download fetchChromSizes
wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/fetchChromSizes

# make both file executable using
chmod +x 

# fetchChromSizes mm10.chromSizes. Note the "." is to specify directory
./fetchChromSizes mm10 > mm10.chromSizes

# download bedGraphToBigWig
wget https://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64.v369/bedGraphToBigWig

# unzip bedgraph file
gunzip bismark/SRR5836474_1_val_1_bismark_bt2_pe.deduplicated.bedGraph.gz

# convert bedgraph file to bigWig
./bedGraphToBigWig bismark/SRR5836474_1_val_1_bismark_bt2_pe.deduplicated.bedGraph.gz mm10.chromSizes SRR5836474.methylation.bigWig

# get coverage
bedtools genomecov -ibam bismark/SRR5836474_1_val_1_bismark_bt2_pe.deduplicated.bam -bg > SRR5836474_genome_coverage.bedgraph

# convert to .bigWig 
./bedGraphToBigWig SRR5836474_genome_coverage.bedgraph mm10.chromSizes SRR5836474_genome_coverage.bigWig

exit
