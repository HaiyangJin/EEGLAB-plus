#!/bin/bash
#SBATCH --job-name=SingleAnalysis      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=3:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=49152      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading  -Xmx2g
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=51-52  # Array definition [1:5, exp code]  201-216,301-316,401-408,501-508  21-24,31-34,41-42,51-52
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r st_Data
