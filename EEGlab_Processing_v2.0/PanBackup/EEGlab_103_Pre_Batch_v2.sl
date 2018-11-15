#!/bin/bash
#SBATCH -J 103
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=6:00:00     # Walltime
#SBATCH --mem-per-cpu=8G    # memory/cpu 
#SBATCH --cpus-per-task=2 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=32    # Array definition 31,32,33 (step 3 and experiment number)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_101_Pre_Batch_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID