#!/bin/bash
#SBATCH -p intel,batch --nodes 1 --ntasks 4 --mem 16G --out logs/antismash.%a.log -J antismash

module unload miniconda2
module unload miniconda3
module load antismash/6.0.0
which perl
which antismash

CPU=1
if [ ! -z $SLURM_CPUS_ON_NODE ]; then
    CPU=$SLURM_CPUS_ON_NODE
fi
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
INPUTFOLDER=predict_results

IFS=,
tail -n +2 $SAMPFILE | sed -n ${N}p | while read SPECIES PHYLUM STRAIN JGILIBRARY BIOSAMPLE BIOPROJECT TAXONOMY_ID ORGANISM_NAME SRA_SAMPID SRA_RUNID LOCUSTAG TEMPLATE KEEPLCG DEPOSITASM
do
    name=$(echo -n "$SPECIES" | perl -p -e 'chomp; s/\s+/_/g')
    species=$(echo -n "$SPECIES" | perl -p -e "s/\s*\Q$STRAIN\E//; chomp;")

    if [ ! -d $OUTDIR/$name ]; then
	echo "No annotation dir for ${name}"
	exit
    fi
    if [[ ! -d $OUTDIR/$name/antismash_local && ! -s $OUTDIR/$name/antismash_local/index.html ]]; then
	antismash --taxon fungi --output-dir $OUTDIR/$name/antismash_local  --genefinding-tool none \
	    --asf --fullhmmer --cassis --clusterhmmer --asf --cb-general --pfam2go --cb-subclusters --cb-knownclusters -c $CPU \
	    $OUTDIR/$name/$INPUTFOLDER/*.gbk
    fi
done
