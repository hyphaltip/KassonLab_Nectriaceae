#!/usr/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=6 --mem 8G
#SBATCH --output=logs/functional.%a.log
#SBATCH --time=1-0:00:00
#SBATCH -p batch -J annotfunc

module unload miniconda2
module unload miniconda3
module load funannotate
module unload perl
module unload python
conda activate funannotate

module load phobius

CPUS=$SLURM_CPUS_ON_NODE

if [ ! $CPUS ]; then
 CPUS=2
fi

INDIR=genomes
OUTDIR=funannotate
mkdir -p $OUTDIR

SAMPFILE=samples.tab
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
SBT=$(realpath lib/Bd_pangenome.sbt)
BUSCO=fungi_odb9
OUTDIR=funannotate
sed -n ${N}p $SAMPFILE | while read SAMP
do
    name=$(echo "$SAMP" | perl -p -e 's/[\(\)]//g')
    PREFIX=$(echo "$name" | perl -p -e 's/\-/./g')
    if [ ! -f $INDIR/$name.masked.fasta ]; then
	echo "No genome for $INDIR/$name.masked.fasta yet - run 00_mash.sh $N"
	exit
    fi
    ODIR=$OUTDIR/$name
    funannotate annotate --busco_db $BUSCO -i $ODIR --species "$SPECIES" --strain "$SAMP" --cpus $CPUS --sbt $SBT
done
