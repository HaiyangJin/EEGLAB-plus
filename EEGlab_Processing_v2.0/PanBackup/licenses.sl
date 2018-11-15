#!/bin/bash
#SBATCH -J matlab
#SBATCH -A uoa00424         # Project Account
#SBATCH --time=1:00:00     # Walltime
#SBATCH --mem-per-cpu=1G    # memory/cpu 
#SBATCH --cpus-per-task=1 
#SBATCH --mail-type=ALL
#SBATCH --mail-user=   
#SBATCH --array=999    # Array definition 1-10 
module load MATLAB/2017b
lmutil lmstat -a