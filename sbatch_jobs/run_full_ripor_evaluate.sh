#!/bin/bash


sbatch --job-name=${base_name} --output=sbatch_jobs/sbatch_out/full_ripor_evaluate.out \
        -p hgx-alpha -G 1 --nodes=1 --cpus-per-task=32 --mem=240G --time=7-00:00:00 \
        --wrap=". /work/hzeng_umass_edu/miniconda3/etc/profile.d/conda.sh && conda activate pag && bash full_scripts/full_ripor_evaluate.sh"