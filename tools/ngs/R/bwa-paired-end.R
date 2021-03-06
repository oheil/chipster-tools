# TOOL bwa-paired-end.R: "BWA-backtrack for paired end reads" (BWA-backtrack aligns paired end reads to genomes with BWA ALN algorithm. Results are sorted and indexed BAM files, which are ready for viewing in the Chipster genome browser. 
# Note that this BWA tool uses publicly available genomes. If you would like to align reads against your own datasets, please use the tool \"BWA for paired-end reads and own genome\".)
# INPUT reads1.txt: "Paired-end read set 1 to align" TYPE GENERIC 
# INPUT reads2.txt: "Paired-end read set 2 to align" TYPE GENERIC 
# OUTPUT bwa.bam 
# OUTPUT bwa.bam.bai 
# OUTPUT bwa.log 
# PARAMETER organism: "Genome" TYPE [Arabidopsis_thaliana.TAIR10.30, Bos_taurus.UMD3.1, Canis_familiaris.CanFam3.1, Drosophila_melanogaster.BDGP6, Felis_catus.Felis_catus_6.2, Gallus_gallus.Galgal4, Gasterosteus_aculeatus.BROADS1, Halorubrum_lacusprofundi_atcc_49239.GCA_000022205.1.30, Homo_sapiens.GRCh37.75, Homo_sapiens.GRCh38, Homo_sapiens_mirna, Medicago_truncatula.GCA_000219495.2.30, Mus_musculus.GRCm38, Mus_musculus_mirna, Oryza_sativa.IRGSP-1.0.30, Ovis_aries.Oar_v3.1, Populus_trichocarpa.JGI2.0.30, Rattus_norvegicus_mirna, Rattus_norvegicus.Rnor_5.0, Rattus_norvegicus.Rnor_6.0, Schizosaccharomyces_pombe.ASM294v2.30, Solanum_tuberosum.3.0.30, Sus_scrofa.Sscrofa10.2, Vitis_vinifera.IGGP_12x.30, Yersinia_enterocolitica_subsp_palearctica_y11.GCA_000253175.1.30, Yersinia_pseudotuberculosis_ip_32953_gca_000834295.GCA_000834295.1.30] DEFAULT Homo_sapiens.GRCh38 (Genome or transcriptome that you would like to align your reads against.)
# PARAMETER quality.format: "Quality value format used" TYPE [solexa1_3: "Illumina GA v1.3-1.5", sanger: Sanger] DEFAULT sanger (Note that this parameter is taken into account only if you chose to apply the mismatch limit to the seed region. Are the quality values in the Sanger format (ASCII characters equal to the Phred quality plus 33\) or in the Illumina Genome Analyzer Pipeline v1.3 or later format (ASCII characters equal to the Phred quality plus 64\)? Please see the manual for details. Corresponds to the command line parameter -I.)
# PARAMETER OPTIONAL seed.length: "Seed length" TYPE INTEGER DEFAULT 32 (Number of first nucleotides to be used as a seed. If the seed length is longer than query sequences, then seeding will be disabled. Corresponds to the command line parameter -l) 
# PARAMETER OPTIONAL seed.edit:"Maximum of differences in the seed" TYPE INTEGER DEFAULT 2 (Maximum differences in the seed. Corresponds to the command line parameter -k )
# PARAMETER OPTIONAL total.edit: "Maximum edit distance for the whole read" TYPE DECIMAL DEFAULT 0.04 ( Maximum edit distance if the value is more than one. If the value is between 1 and 0 then it defines the fraction of missing alignments given 2% uniform base error rate. In the latter case, the maximum edit distance is automatically chosen for different read lengths. Corresponds to the command line parameter -n.)
# PARAMETER OPTIONAL num.gaps: "Maximum number of gap openings" TYPE INTEGER DEFAULT 1 (Maximum number of gap openings for one read. Corresponds to the command line parameter -o.)
# PARAMETER OPTIONAL num.extensions: "Maximum number of gap extensions" TYPE INTEGER DEFAULT -1 (Maximum number of gap extensions, -1 for disabling long gaps. Corresponds to the command line parameter -e.)
# PARAMETER OPTIONAL gap.opening: "Gap open penalty " TYPE INTEGER DEFAULT 11 (Gap opening penalty. Corresponds to the command line parameter -O.)
# PARAMETER OPTIONAL gap.extension: "Gap extension penalty " TYPE INTEGER DEFAULT 4 (Gap extension penalty. Corresponds to the command line parameter -E.)
# PARAMETER OPTIONAL mismatch.penalty: "Mismatch penalty threshold" TYPE INTEGER DEFAULT 3 (BWA will not search for suboptimal hits with a score lower than defined. Corresponds to the command line parameter -M.)
# PARAMETER OPTIONAL disallow.gaps: "Disallow gaps in region"  TYPE INTEGER DEFAULT 16 (Disallow a long deletion within the given number of bp towards the 3\'-end. Corresponds to the command line parameter -d.)
# PARAMETER OPTIONAL disallow.indel: "Disallow indels within the given number of bp towards the ends"  TYPE INTEGER DEFAULT 5 (Do not put an indel within the defined value of bp towards the ends. Corresponds to the command line parameter -i.)
# PARAMETER OPTIONAL trim.threshold: "Quality trimming threshold" TYPE INTEGER DEFAULT 0 (Quality threshold for read trimming down to 35bp. Corresponds to the command line parameter -q.)
# PARAMETER OPTIONAL barcode.length: "Barcode length"  TYPE INTEGER DEFAULT 0 (Length of barcode starting from the 5 pime-end. The barcode of each read will be trimmed before mapping. Corresponds to the command line parameter -B.)
# PARAMETER OPTIONAL alignment.no: "Maximum number of hits to report for paired reads" TYPE INTEGER DEFAULT 3 (Maximum number of alignments to output in the XA tag for reads paired properly. If a read has more than the given amount of hits, the XA tag will not be written. Corresponds to the command line parameter bwa sampe -n.)
# PARAMETER OPTIONAL max.discordant: "Maximum number of hits to report for discordant pairs" TYPE INTEGER DEFAULT 10 (Maximum number of alignments to output in the XA tag for disconcordant read pairs, excluding singletons. If a read has more than INT hits, the XA tag will not be written. Corresponds to the command line parameter bwa sampe -N.) 
# PARAMETER OPTIONAL max.insert: "Maximum insert size" TYPE INTEGER DEFAULT 500 (Maximum insert size for a read pair to be considered being mapped properly. This option is only used when there are not enough good alignments to infer the distribution of insert sizes. Corresponds to the command line parameter bwa sampe -a.)
# PARAMETER OPTIONAL max.occurrence: "Maximum occurrences for one end" TYPE INTEGER DEFAULT 100000 (Maximum occurrences of a read for pairing. A read with more occurrneces will be treated as a single-end read. Reducing this parameter helps faster pairing. The default value is 100000. For reads shorter than 30bp, applying a smaller value is recommended to get a sensible speed at the cost of pairing accuracy. Corresponds to the command line parameter bwa sampe -o.)

# KM 26.8.2011
# AMS 19.6.2012 Added unzipping
# AMS 11.11.2013 Added thread support

# check out if the file is compressed and if so unzip it
source(file.path(chipster.common.path, "zip-utils.R"))
unzipIfGZipFile("reads1.txt")
unzipIfGZipFile("reads2.txt")

# bwa
bwa.binary <- file.path(chipster.tools.path, "bwa", "bwa")
#bwa.indexes <- file.path(chipster.tools.path, "bwa_indexes")
bwa.genome <- file.path(chipster.tools.path, "genomes", "indexes", "bwa", organism)
command.start <- paste("bash -c '", bwa.binary)

###
# common parameters for bwa runs
###
# mode specific parameters
if (total.edit >= 1) {
	total.edit <- round(total.edit)
}
quality.parameter <- ifelse(quality.format == "solexa1_3", "-I", "")
mode.parameters <- paste("aln", "-t", chipster.threads.max, "-o", num.gaps, "-e", num.extensions, "-d", disallow.gaps, "-i" , disallow.indel , "-l" , seed.length , "-k" , seed.edit , "-O" , gap.opening , "-E" , gap.extension , "-q" , trim.threshold, "-B" , barcode.length , "-M" , mismatch.penalty , "-n" , total.edit , quality.parameter)


###
# run the first set
###
echo.command <- paste("echo '", bwa.binary , mode.parameters, bwa.genome, "reads1.txt ' > bwa.log" )
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(echo.command)
command.end <- paste(bwa.genome, "reads1.txt 1> alignment1.sai 2>> bwa.log'")
bwa.command <- paste(command.start, mode.parameters, command.end)
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(bwa.command)


###
# run the second set
###
echo.command <- paste("echo '", bwa.binary , mode.parameters, bwa.genome, "reads2.txt ' >> bwa.log" )
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(echo.command)
command.end <- paste(bwa.genome, "reads2.txt 1> alignment2.sai 2>> bwa.log'")
bwa.command <- paste(command.start, mode.parameters, command.end)
#stop(paste('CHIPSTER-NOTE: ', bwa.command))
system(bwa.command)

system("ls -l >> bwa.log")

###
# sai to sam conversion
###
sampe.parameters <- paste("sampe -n", alignment.no, "-a", max.insert, "-o" , max.occurrence , "-N" , max.discordant )
sampe.end <- paste(bwa.genome, "alignment1.sai alignment2.sai reads1.txt reads2.txt 1> alignment.sam 2>>bwa.log'" )
sampe.command <- paste( command.start, sampe.parameters , sampe.end )
system(sampe.command)

		
# samtools binary
samtools.binary <- c(file.path(chipster.tools.path, "samtools", "samtools"))

# convert sam to bam
system(paste(samtools.binary, "view -bS alignment.sam -o alignment.bam"))

# sort bam
system(paste(samtools.binary, "sort alignment.bam alignment.sorted"))

# index bam
system(paste(samtools.binary, "index alignment.sorted.bam"))

# rename result files
system("mv alignment.sorted.bam bwa.bam")
system("mv alignment.sorted.bam.bai bwa.bam.bai")

# Handle output names
#
source(file.path(chipster.common.path, "tool-utils.R"))

# read input names
inputnames <- read_input_definitions()

# Determine base name
base1 <- strip_name(inputnames$reads1.txt)
base2 <- strip_name(inputnames$reads2.txt)
basename <- paired_name(base1, base2)

# Make a matrix of output names
outputnames <- matrix(NA, nrow=2, ncol=2)
outputnames[1,] <- c("bwa.bam", paste(basename, ".bam", sep =""))
outputnames[2,] <- c("bwa.bam.bai", paste(basename, ".bam.bai", sep =""))

# Write output definitions file
write_output_definitions(outputnames)