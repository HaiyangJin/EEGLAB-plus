#!/bin/bash
#SBATCH -J erp-image
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=00:30:00     # Walltime
#SBATCH --mem-per-cpu=48G    # memory/cpu 
#SBATCH --cpus-per-task=1
#SBATCH --profile=task
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r trialmulti 