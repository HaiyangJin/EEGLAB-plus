#!/bin/bash
#SBATCH --job-name=120_Iall      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=00:05:00         # Walltime (HH:MM:SS)
#SBATCH --mem=3G      # memory/cpu (in MB)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=large        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1200-1219,1301-1320,1401-1430,1500-1535   # Array definition 1101-1121 1200-1219 1301-1320 1401-1430 1500-1535([1]individual(1), all(1) and Participant numbers)

module load MATLAB/2017b

matlab -nodisplay -r "EEGlab_120_PreProcessed"