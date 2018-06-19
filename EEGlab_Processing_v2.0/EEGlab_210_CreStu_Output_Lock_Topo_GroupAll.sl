#!/bin/bash
#SBATCH -J 210_Gall
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=8G    # memory/cpu 
#SBATCH --cpus-per-task=2 
#SBATCH --profile=task
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=4100,4200    # Array definition (4100,4200,4300,4400 [4]group(2),all(2),experimentNum(1234),00)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_210_CreStu_Output_Lock_Topo $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID