#!/bin/bash
#SBATCH --job-name=SingleAnalysis      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=00:30:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=49152      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r singleTrial