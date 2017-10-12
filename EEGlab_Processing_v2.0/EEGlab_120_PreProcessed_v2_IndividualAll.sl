#!/bin/bash
#SBATCH -J 120_Iall
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=4G    # memory/cpu 
#SBATCH --cpus-per-task=1
#SBATCH --profile=task 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=12101-12121    # Array definition 12101-12121 12200-12219 12301-12320 12401 (individual(1), all(2) and Participant numbers)
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID