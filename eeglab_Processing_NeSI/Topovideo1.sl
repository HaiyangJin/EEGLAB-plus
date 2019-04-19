#!/bin/bash
#SBATCH --job-name=topomovie1      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=1:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=60G      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading  -Xmx2g
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --output=Topovideo1_%j.out # Include the job ID in the names of
#SBATCH --array=2-4  # Array definition [1:5, exp code]  2 3 4 5
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r Topovideo1
