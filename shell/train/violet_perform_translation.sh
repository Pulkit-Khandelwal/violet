############################################
dataset_base_path=$1
date=$2
step_version=$3
gpu_ids=$4
max_epochs=$5
model_name=$6
model_optim=$7
subjs_train=$8
subjs_valid=$9
subjs_test=${10}
base_dir=${11}
exp_name=${12}
CT_name=${13}
MR_name=${14}
exp_name_use=${15}
plane=${16}


############################################
########### make_hdf5 and make_hist_dataset (train and valid)
save_hdf5_path="${dataset_base_path}/pickled_files"
mkdir -p ${save_hdf5_path}

is_test="False"
run_type="train"
bash ../data/make_hdf5.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} ${save_hdf5_path} ${is_test} ${plane} "${subjs_train[*]}"
bash ../data/make_hist_dataset.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} "${subjs_train[@]}" ${plane} ${save_hdf5_path}

run_type="valid"
bash ../data/make_hdf5.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} ${save_hdf5_path} ${is_test} ${plane} "${subjs_valid[*]}"
bash ../data/make_hist_dataset.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} "${subjs_valid[@]}" ${plane} ${save_hdf5_path}

############################################
########### train the model
prev_exp_dir=${base_dir}/${exp_name_use}
bash ../train/train.sh ${date} ${step_version} ${save_hdf5_path} ${gpu_ids} ${max_epochs} ${plane} ${prev_exp_dir}

############################################
########### make_hdf5 and make_hist_dataset
# We need to run the inference on the training set
# Let us get mutiple pickled files for all the training data
# so that we can do the inference in parallel (we can't directky use the one from above)
# Populate the below from you training set

subjs_test_1=()
subjs_test_2=()
subjs_test_3=()
subjs_test_4=()

is_test=True
run_type="test"
for count in {1..4}
do

echo ${count}
save_hdf5_path="${dataset_base_path}/pickled_files_test_set_${count}"
mkdir -p ${save_hdf5_path}

subjs_array_name="subjs_test_${count}"
eval "subjs=(\"\${${subjs_array_name}[@]}\")"
echo "Subjects: ${subjs[@]}"

bash shell/data/make_hdf5.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} ${save_hdf5_path} ${is_test} ${plane} "${subjs[*]}"
bash shell/data/make_hist_dataset.sh ${CT_name} ${MR_name} ${run_type} ${dataset_base_path} "${subjs[*]}" ${plane} ${save_hdf5_path}
done


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

for count in {1..4}
do
echo ${count}
save_hdf5_path="${dataset_base_path}/pickled_files_test_set_${count}"
gpu_ids=${count}
bash ../test/test.sh ${date} ${exp_name} ${gpu_ids} ${save_hdf5_path} ${plane} ${base_dir} ${max_epochs} &
done
wait
