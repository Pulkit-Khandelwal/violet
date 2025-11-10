#!/bin/bash
date=$1
step_version=$2
dataset_path=$3
gpu_ids=$4
max_epoch=$5
plane=$6
prev_exp_dir=$7

config_name="BBDM_base.yaml"
HW="160"
batch=16
ddim_eta=0.0
prefix="MR_global_hist_context"

exp_name="${date}_${HW}_BBDM_${plane}_DDIM_${prefix}_${step_version}"

python3 -u ../../main.py \
    --train \
    --exp_name $exp_name \
    --config ../configs/$config_name \
    --HW $HW \
    --plane ${plane} \
    --batch $batch \
    --ddim_eta $ddim_eta \
    --sample_at_start \
    --save_top \
    --hist_type 'normal' \
    --dataset_path ${dataset_path} \
    --gpu_ids ${gpu_ids} \
    --max_epoch ${max_epoch}
