#!/bin/bash
#SBATCH -J SortOut
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=16G    # memory/cpu 
#SBATCH --cpus-per-task=1  
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r SortOutPreFiles 