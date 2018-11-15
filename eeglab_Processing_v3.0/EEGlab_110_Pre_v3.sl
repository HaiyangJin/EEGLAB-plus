#!/bin/bash
#SBATCH --job-name=110     # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=24:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=10240      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=6       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=407-430   # Array definition 101-121 200-219 301-320 401-420
module load MATLAB/2017b
matlab -nodesktop -nosplash -r EEGlab_110_Pre_v3 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID
