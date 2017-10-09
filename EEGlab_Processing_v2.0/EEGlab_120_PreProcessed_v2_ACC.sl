#!/bin/bash
#SBATCH -J 120_acc
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=4G    # memory/cpu 
#SBATCH --cpus-per-task=1
#SBATCH --profile=task 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1301-1320   # Array definition 1101-1121 1200-1219 1301-1320 1401 (1 and participant numbers)
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID