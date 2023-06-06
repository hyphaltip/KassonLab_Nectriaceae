#!/bin/bash -l
#SBATCH --nodes 1 -c 24 -n 1 --mem 64G -p batch --out logs/annotate.%a.log
# note this doesn't need that much memory EXCEPT for the XML -> tsv parsing that happens when you provided an interpro XML file

#!/bin/bash -l
#SBATCH --nodes 1 --ntasks 24 --mem 128G --out logs/train.%a.log -J trainRhod --time 96:00:00

MEM=128G
module load funannotate

#export PASAHOME=`dirname $(which Launch_PASA_pipeline.pl)`
RNADIR=lib/RNASeq
CPUS=$SLURM_CPUS_ON_NODE

if [ ! $CPUS ]; then
    CPUS=2
fi
SAMPLES=samples.csv
N=${SLURM_ARRAY_TASK_ID}

if [ -z $N ]; then
    N=$1
    if [ -z $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=$(wc -l $SAMPLES | awk '{print $1}')
if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPLES"
    exit
fi

INDIR=final_genomes
OUTDIR=annotation
BUSCODB=basidiomycota_odb10
SBTTEMPLATE=lib/sbt
IFS=,
tail -n +2 $SAMPLES | sed -n ${N}p | while read BASE SPECIES STRAIN NANOPORE ILLUMINA SUBPHYLUM PHYLUM LOCUS RNASEQ
do
    name=$BASE
    GENOME=$INDIR/$BASE.masked.fasta
    IPRSCAN=
    funannotate annotate -i $OUTDIR/$BASE --cpus $CPUS  \
		--species "$SPECIES" --strain $STRAIN --sbt $SBTTEMPLATE/$BASE.sbt \
		-o $OUTDIR/$BASE --busco_db $BUSCODB --rename $LOCUS
done


