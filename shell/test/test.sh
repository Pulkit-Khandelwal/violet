#!/bin/bash
# Change: Clean the config file by removing the string with "!!"
# ${base_path}/${exp_name}/checkpoint/config_fixed.yaml

date=$1
exp_name=$2
gpu_ids=$3
save_hdf5_path=$4
plane=$5
base_path=$6
max_epochs=$7 # epoch for the current exp

resume_model_name=$(basename "$(ls ${base_path}/${exp_name}/checkpoint/top_model* 2>/dev/null | head -n 1)")
resume_optim_name=$(basename "$(ls ${base_path}/${exp_name}/checkpoint/top_optim_sche* 2>/dev/null | head -n 1)")

resume_model=${base_path}/${exp_name}/checkpoint/${resume_model_name}
resume_optim=${base_path}/${exp_name}/checkpoint/${resume_optim_name}

config_name="BBDM_base.yaml"
HW="160"
batch=1
ddim_eta=0.0
prefix="MR_global_hist_context"

sample_step=100
inference_type="normal"
ISTA_step_size=0.5
num_ISTA_step=1

python3 -u ../../main.py \
    --exp_name $exp_name \
    --config ${base_path}/${exp_name}/checkpoint/config_fixed.yaml \
    --sample_to_eval \
    --gpu_ids $gpu_ids \
    --HW $HW \
    --batch $batch \
    --plane $plane \
    --ddim_eta $ddim_eta \
    --sample_step $sample_step \
    --inference_type $inference_type \
    --ISTA_step_size $ISTA_step_size \
    --num_ISTA_step $num_ISTA_step \
    --hist_type 'normal' \
    --dataset_path ${save_hdf5_path} \
    --resume_model $resume_model \
    --resume_optim $resume_optim
