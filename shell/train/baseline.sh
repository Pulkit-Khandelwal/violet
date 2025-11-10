####################################################################################################
# This is the baseline model:
# First we will translate and then perform registration
####################################################################################################

########################################################################
###### Dataset splits for train, val, and test
########################################################################
subjs_valid=()
subjs_train=()
subjs_test=()

########################################################################
###### Fixed and Variable parameters
########################################################################
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

date="19910806"
gpu_ids=0
reg_method_type="fireants" # or "greedy"
fixed_image="invivo"
max_epochs=50

step_version="baseline"
exp_name="${date}_${HW}_BBDM_${plane}_DDIM_${prefix}_${step_version}"

dataset_base_path=${mri_fixed_path}
save_hdf5_path=${dataset_base_path}/pickled_files
mkdir -p ${save_hdf5_path}

############################################
########### TRAINING
############################################

########### make_hdf5 and make_hist_dataset (train)
is_test="False"
run_type="train"
bash ../data/make_hdf5.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} ${save_hdf5_path} ${is_test} ${plane} "${subjs_train[*]}"
bash ../data/make_hist_dataset.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} "${subjs_train[@]}" ${plane} ${save_hdf5_path}


########### train the model
config_name="BBDM_base.yaml"
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
    --dataset_path ${save_hdf5_path} \
    --gpu_ids ${gpu_ids} \
    --max_epoch ${max_epochs}


############################################
########### TESTING
############################################
########### make_hdf5 and make_hist_dataset (for the test set)

is_test=True
run_type="test"
save_hdf5_path="${dataset_base_path}/pickled_files_test"
mkdir -p ${save_hdf5_path}


bash ..data/make_hdf5.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} ${save_hdf5_path} ${is_test} ${plane} "${subjs_test[*]}"
bash ../data/make_hist_dataset.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} "${subjs_test[*]}" ${plane} ${save_hdf5_path}

########### test the model
sed -E 's/!![^ ]+//g' ${base_dir}/${exp_name}/checkpoint/config.yaml > ${base_dir}/${exp_name}/checkpoint/config_fixed.yaml
config_yaml_file=${base_dir}/${exp_name}/checkpoint/config_fixed.yaml

yq -i -y ".data.dataset_config.raw_data_dir = \"${dataset_base_path}\"" ${config_yaml_file}
yq -i -y ".data.dataset_config.MR_name = \"${MR_name}\"" ${config_yaml_file}
yq -i -y ".data.dataset_config.CT_name = \"${CT_name}\"" ${config_yaml_file}
yq -i -y ".result.ckpt_path = \"${base_dir}/${exp_name}/checkpoint\"" ${config_yaml_file}
yq -i -y ".result.image_path = \"${base_dir}/${exp_name}/image\"" ${config_yaml_file}
yq -i -y ".result.log_path = \"${base_dir}/${exp_name}/log\"" ${config_yaml_file}
yq -i -y ".data.dataset_config.plane = \"${plane}\"" ${config_yaml_file}

gpu_ids=0
bash ../test/test.sh ${date} ${exp_name} ${gpu_ids} ${save_hdf5_path} ${plane} ${base_dir} ${max_epochs}


########################################################################
########### S2: register [register orig_exvivo to synth_exvivo] and then warp [warp orig_exvivo to the invivo space]
########################################################################

model_name=$(basename "$(ls ${base_dir}/${exp_name}/checkpoint/top_model* 2>/dev/null | head -n 1)")

bash violet_perform_registration.sh ${reg_method_type} \
${base_dir} \
${exp_name} \
${model_name} \
${dataset_base_path} \
${fixed_image} \
${mri_fixed_path} \
"${subjs_test[*]}"
