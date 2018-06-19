#!/bin/bash
#SBATCH -J 120_Iall
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=4G    # memory/cpu 
#SBATCH --cpus-per-task=1
#SBATCH --profile=task 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=3423-3424   # Array definition 3101-3121 3200-3219 3301-3320 3401 ([3]individual(1), all(2) and Participant numbers)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID