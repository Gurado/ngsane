#!/bin/bash -e

# Script to run mrsfast program.
# It takes a fasta file as input and creates an index.
# author: Fabian Buske
# date: August 2014

# QCVARIABLES,Resource temporarily unavailable
# RESULTFILENAME $FASTA.index


echo ">>>>> index generation for mrsfast"
echo ">>>>> startdate "`date`
echo ">>>>> hostname "`hostname`
echo ">>>>> job_name "$JOB_NAME
echo ">>>>> job_id "$JOB_ID
echo ">>>>> $(basename $0) $*"

function usage {
echo -e "usage: $(basename $0) -k [OPTIONS]"
exit
}


if [ ! $# -gt 1 ]; then usage ; fi

#INPUTS                                                                                                           
while [ "$1" != "" ]; do
    case $1 in
        -k | --toolkit )        shift; CONFIG=$1 ;; # location of the NGSANE repository                       
        --recover-from )        shift; RECOVERFROM=$1 ;; # attempt to recover from log file
        -h | --help )           usage ;;
        * )                     echo "don't understand "$1
    esac
    shift
done

#PROGRAMS
. $CONFIG
. ${NGSANE_BASE}/conf/header.sh
. $CONFIG

################################################################################
CHECKPOINT="programs"

# save way to load modules that itself loads other modules
hash module 2>/dev/null && for MODULE in $MODULE_MRSFAST; do module load $MODULE; done && module list 

export PATH=$PATH_MRSFAST:$PATH
echo "PATH=$PATH"

echo -e "--NGSANE      --\n" $(trigger.sh -v 2>&1)
echo -e "--mrsfast     --\n "$(mrsfast --version)
[ -z "$(which mrsfast)" ] && echo "[ERROR] no mrsfast detected" && exit 1

echo -e "\n********* $CHECKPOINT\n"
################################################################################
CHECKPOINT="parameters"

if [ -z "$FASTA" ]; then
    echo "[ERROR] no reference provided (FASTA)"
    exit 1
fi

echo -e "\n********* $CHECKPOINT\n"
################################################################################
CHECKPOINT="recall files from tape"

if [ -n "$DMGET" ]; then
	dmget -a $(dirname $FASTA)/*
fi
    
echo -e "\n********* $CHECKPOINT\n"
################################################################################
CHECKPOINT="generating the index files"

if [[ -n "$RECOVERFROM" ]] && [[ $(grep -P "^\*{9} $CHECKPOINT" $RECOVERFROM | wc -l ) -gt 0 ]] ; then
    echo "::::::::: passed $CHECKPOINT"
else 

    if [ ! -e $FASTA.index ]; then 
        echo "[NOTE] make index"; 
        mrsfast --index $MRSFASTINDEXADDPARAM $FASTA; 
    fi
    if [ ! -e $FASTA.fai ]; then 
        echo "[NOTE] make .fai"; 
        samtools faidx $FASTA; 
    fi

    # mark checkpoint
    if [ -f ${FASTA%.*}.index ];then echo -e "\n********* $CHECKPOINT\n"; unset RECOVERFROM; else echo "[ERROR] checkpoint failed: $CHECKPOINT"; exit 1; fi
fi 

echo -e "\n********* $CHECKPOINT\n"
################################################################################
[ -e $FASTA.index.dummy ] && rm $FASTA.index.dummy
echo ">>>>> index generation for mrsfast - FINISHED"
echo ">>>>> enddate "`date`
