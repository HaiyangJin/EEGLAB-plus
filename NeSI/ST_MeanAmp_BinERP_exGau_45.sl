#!/bin/bash
#SBATCH --job-name=ST_45      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=3:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem=12G      # memory/cpu (in MB)
#SBATCH --cpus-per-task=2       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=large        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading  -Xmx2g
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --output=ST_%A_%a.out # Include the job ID in the names of
#SBATCH --array=41-42,51-52 # Array definition [1:5, exp code]  41-42

module load MATLAB/2017b

srun matlab -nodesktop -nosplash -r ST_MeanAmp_BinERP_exGau