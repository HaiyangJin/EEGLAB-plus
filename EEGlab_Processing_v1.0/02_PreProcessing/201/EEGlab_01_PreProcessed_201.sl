#!/bin/bash
#SBATCH -J 201_012
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=2:00:00     # Walltime
#SBATCH --mem-per-cpu=32G    # memory/cpu 
#SBATCH --cpus-per-task=4 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1-13,15-21     # Array definition 1-10     14,16-21
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_01_PreProcessed_201 $SLURM_ARRAY_TASK_ID