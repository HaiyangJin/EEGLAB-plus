#!/bin/bash
#SBATCH -J 210_ACC
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=6:00:00     # Walltime
#SBATCH --mem-per-cpu=8G    # memory/cpu 
#SBATCH --cpus-per-task=2 
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=311    # Array definition (experimentNum(1234),isManualRejected(01),isBasedACC(1))
module load MATLAB/2016b
srun matlab -nodesktop -nosplash -r EEGlab_210_CreStu_Output_Lock_Topo $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID