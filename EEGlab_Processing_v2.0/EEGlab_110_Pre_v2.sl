#!/bin/bash
#SBATCH -J 110
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=24:00:00     # Walltime
#SBATCH --mem-per-cpu=10G    # memory/cpu 
#SBATCH --cpus-per-task=4
#SBATCH --profile=task
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=402    # Array definition 101-121 200-219 301-320 401
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_110_Pre_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID