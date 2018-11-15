#!/bin/bash
#SBATCH --job-name=120_Iall      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=01:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=4096      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1401-1430   # Array definition 1101-1121 1200-1219 1301-1320 1401-1430 ([1]individual(1), all(1) and Participant numbers)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v3 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID