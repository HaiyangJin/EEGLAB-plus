#!/bin/bash
#SBATCH --job-name=102     # job name (shows up in the queue)
#SBATCH --account=uoa00424     # Project Account
#SBATCH --time=20:00:00         # Walltime (HH:MM:SS)
#SBATCH --mem-per-cpu=10240      # memory/cpu (in MB)
#SBATCH --ntasks=1              # number of tasks (e.g. MPI)
#SBATCH --cpus-per-task=6       # number of cores per task (e.g. OpenMP)
#SBATCH --partition=bigmem        # specify a partition
#SBATCH --hint=nomultithread    # don't use hyperthreading
#SBATCH --mail-type=END
#SBATCH --mail-user=hjin317@aucklanduni.ac.nz
#SBATCH --array=2401-2430    # Array definition 2101-2121, 2200-2219, 2301-2320, 2401-2430(experiment number and step 2)
module load MATLAB/2017b
matlab -nodesktop -nosplash -r EEGlab_102_Pre_Batch_v3 $SLURM_ARRAY_TASK_ID $SLURM_ARRAY_JOB_ID