
########################################################################
###### Dataset splits for train, val, and test
########################################################################
subjs_valid=()
subjs_train=()
subjs_test=()

######################################
######################################
###### Fixed parameters
HW="160"
plane="sagittal"
batch=16
ddim_eta=0.0
prefix="MR_global_hist_context"
CT_name="_invivo_mri.nii.gz"
MR_name="_exvivo_mri.nii.gz"
base_dir=shell/train/results/ct2mr_160

mri_fixed_path=/working_dir/files_warped/for_translate
labels_fixed_path=/working_dir/files_warped/for_translate/labels

###### Variable parameters
date="19910806"
gpu_ids=0
reg_method_type="fireants" # or "greedy"
fixed_image="invivo"

max_epochs=20
for counter in {1..5}
do

  if [[ $counter -eq 1 ]]; then
    echo ${counter}
    dataset_base_path=${mri_fixed_path}
    exp_name_use="NA"
  else
    echo ${counter}
    prev_counter=$((counter - 1))
    exp_name_use="${date}_${HW}_BBDM_${plane}_DDIM_${prefix}_step_${prev_counter}"
    prev_model_name=$(basename "$(ls ${base_dir}/${exp_name_use}/checkpoint/top_model* 2>/dev/null | head -n 1)")
    dataset_base_path=${base_dir}/${exp_name_use}/sample_to_eval/${prev_model_name}/normal_100/registration/${reg_method_type}/orig_modality
  fi
    step_version=step_${counter}
    exp_name="${date}_${HW}_BBDM_${plane}_DDIM_${prefix}_${step_version}"
    model_name="NA"
    model_optim="NA"

    #### S1: translate [exvivo CT-->MR (invivo-->exvivo)]
    bash violet_perform_translation.sh ${dataset_base_path} \
    ${date} \
    ${step_version} \
    ${gpu_ids} \
    ${max_epochs} \
    ${model_name} \
    ${model_optim} \
    "${subjs_train[*]}" \
    "${subjs_valid[*]}" \
    "${subjs_test[*]}" \
    ${base_dir} \
    ${exp_name} \
    ${CT_name} \
    ${MR_name} \
    ${exp_name_use} \
    ${plane}


    #### S2: register [register orig_exvivo to synth_exvivo] and then warp [warp orig_exvivo to the invivo space]
    model_name=$(basename "$(ls ${base_dir}/${exp_name}/checkpoint/top_model* 2>/dev/null | head -n 1)")
    dataset_base_path=/working_dir/files_warped/for_translate_160_12mm_LPI
    mri_fixed_path=/working_dir/files_warped/for_translate_160_12mm_LPI
    
    bash violet_perform_registration.sh ${reg_method_type} \
    ${base_dir} \
    ${exp_name} \
    ${model_name} \
    ${dataset_base_path} \
    ${fixed_image} \
    ${mri_fixed_path} \
    "${subjs_test[*]}"

done
