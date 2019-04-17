#!/bin/bash
#SBATCH --job-name=topomovie2      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=1:30:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=2G      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=large        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading  -Xmx2g
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --output=Topovideo2_%j.out # Include the job ID in the names of
#SBATCH --array=201-216  # Array definition [1:5, exp code]  ID should be 201-216,301-316,401-408,501-508
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r Topovideo_2
