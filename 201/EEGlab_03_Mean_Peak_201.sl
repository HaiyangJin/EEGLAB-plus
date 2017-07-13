#!/bin/bash
#SBATCH -J 201_03
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=6:00:00     # Walltime
#SBATCH --mem-per-cpu=16G    # memory/cpu 
#SBATCH --cpus-per-task=4 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_03_Mean_Peak_201