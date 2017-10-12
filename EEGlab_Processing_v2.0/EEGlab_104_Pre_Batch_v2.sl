#!/bin/bash
#SBATCH -J 104
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=2:00:00     # Walltime
#SBATCH --mem-per-cpu=8G    # memory/cpu 
#SBATCH --cpus-per-task=4 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=4301-4320    # Array definition 4101-4121, 4200-4219, 4301-4320 (experiment number and step 4)
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_102_Pre_Batch_v2 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID