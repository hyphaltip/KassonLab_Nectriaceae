#!/bin/bash
#SBATCH --ntasks 32 --nodes 1 --mem 80G -p intel,batch
#SBATCH --time 12:00:00 --out logs/iprscan.%a.log
hostname
CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
# let's pick this more hard-codeed based on the number of embeded workers that will run
SPLIT_CPU=8
JOBSPLIT=100
OUTDIR=annotate
SAMPFILE=samples_prefix.csv
N=${SLURM_ARRAY_TASK_ID}
if [ ! $N ]; then
    N=$1
    if [ ! $N ]; then
        echo "need to provide a number by --array or cmdline"
        exit
    fi
fi
MAX=`wc -l $SAMPFILE | awk '{print $1}'`

if [ $N -gt $MAX ]; then
    echo "$N is too big, only $MAX lines in $SAMPFILE"
    exit
fi
IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
    name=$(echo -n "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
    species=$(echo -n "$SPECIES" | perl -p -e "s/\s*\Q$STRAIN\E//; chomp'")
    if [ ! -d $OUTDIR/$name ]; then
	echo "No annotation dir for ${name}"
	exit
    fi
    mkdir -p $OUTDIR/$name/annotate_misc
    XML=$OUTDIR/$name/annotate_misc/iprscan.xml
    if [ ! -f $XML ]; then
	module unload miniconda2
	module unload anaconda3
	module unload miniconda3
	module load funannotate
	module load iprscan/5.51-85.0
	module load workspace/scratch
	export TMPDIR=$SCRATCH
	export TEMP=$SCRATCH
	export TMP=$SCRATCH
    	IPRPATH=$(which interproscan.sh)
	echo $IPRPATH
	time funannotate iprscan -i $OUTDIR/$name -o $XML -m local -c $SPLIT_CPU --iprscan_path $IPRPATH -n $JOBSPLIT
    fi
done
