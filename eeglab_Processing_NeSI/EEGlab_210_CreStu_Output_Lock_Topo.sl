#!/bin/bash
#SBATCH --job-name=210_Iall      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=1:40:00         # Walltime (HH:MM:SS)
#SBATCH --mem=6G      # memory/cpu (in MB)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=large        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=1200,1300,1400,1500    # Array definition (1100,1200,1300,1400,1500 [1](Individual(1),all(1)),experimentNum(1234),00)

module load MATLAB/2017b

matlab -nodisplay -r "EEGlab_210_CreStu_Output_Lock_Topo"