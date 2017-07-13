#!/bin/bash
#SBATCH -J 202_01
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=12:00:00     # Walltime
#SBATCH --mem-per-cpu=32G    # memory/cpu 
#SBATCH --cpus-per-task=4 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1-20    # Array definition 1-10
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_01_Pre_202 $SLURM_ARRAY_TASK_ID
