#!/bin/bash
#SBATCH --job-name=210_Iacc      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=00:30:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=8192      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=2500    # Array definition (2100,2200,2300,2400,2500 [2]Individual(1),acc(2),experimentNum(1234),00)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_210_CreStu_Output_Lock_Topo_v3 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID