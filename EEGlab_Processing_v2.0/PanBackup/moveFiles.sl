#!/bin/bash
#SBATCH -J matlab
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=16G    # memory/cpu 
#SBATCH --cpus-per-task=1 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=    
#SBATCH --array=1    # Array definition
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r moveFiles $SLURM_ARRAY_TASK_ID