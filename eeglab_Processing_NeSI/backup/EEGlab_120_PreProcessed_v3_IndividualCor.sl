#!/bin/bash
#SBATCH --job-name=120_Iacc      # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=00:10:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=4096      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=1       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=2500-2508  # Array definition 2101-2121 2200-2219 2301-2320 2401-2430 2501-2508 ([2]Individual(1), acc(2) and participant numbers)
module load MATLAB/2017b
srun matlab -nodesktop -nosplash -r EEGlab_120_PreProcessed_v3 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID