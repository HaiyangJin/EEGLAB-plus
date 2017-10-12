#!/bin/bash
#SBATCH -J 120_Iacc
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=4G    # memory/cpu 
#SBATCH --cpus-per-task=1
#SBATCH --profile=task 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=11101-11121   # Array definition 11101-11121 11200-11219 11301-11320 11401 (Individual(1), acc(1) and participant numbers)
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID