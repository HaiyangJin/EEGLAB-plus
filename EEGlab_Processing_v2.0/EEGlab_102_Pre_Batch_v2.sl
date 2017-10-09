#!/bin/bash
#SBATCH -J 102
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=24:00:00     # Walltime
#SBATCH --mem-per-cpu=16G    # memory/cpu 
#SBATCH --cpus-per-task=2
#SBATCH --profile=task 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=2103-2104    # Array definition 2101-2121 2200-2219,2301-2220 (experiment number and step 2)
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_102_Pre_Batch_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID