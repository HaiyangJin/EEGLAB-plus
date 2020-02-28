#!/bin/bash
#SBATCH --job-name=topomovie2      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=3:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem=2G      # memory/cpu (in MB)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=prepost        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading  -Xmx2g
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --output=Topovideo2_%A_%a.out # Include the job ID in the names of  1501-1508,2501-2508,3501-3508,10501-10508,9501-9508,8501-8508,501-508
#SBATCH --array=201-216,301-316,401-408,501-508  # Array definition [1:5, exp code]  ID should be 201-216,301-316,401-408,501-508,1401-1408,2401-2408,

module load MATLAB/2017b

matlab -nodisplay -r Topovideo2
