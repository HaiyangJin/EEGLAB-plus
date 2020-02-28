#!/bin/bash
#SBATCH --job-name=110     # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=20:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem=120G      # memory/cpu (in MB)
#SBATCH --cpus-per-task=4       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=   # Array definition 101-121 200-219 301-320 401-430 500-535 -219,301-320,401-430,500-535

module load MATLAB/2017b

matlab -nodisplay -r EEGlab_110_Pre 
