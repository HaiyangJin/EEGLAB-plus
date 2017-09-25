#!/bin/bash
#SBATCH -J 202_02
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=6:00:00     # Walltime
#SBATCH --mem-per-cpu=32G    # memory/cpu 
#SBATCH --cpus-per-task=4 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_02_CreStu_Output_202