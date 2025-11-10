####################################################################################################
# Perform registration with different methods (greedy or fireants)
####################################################################################################
reg_method_type=$1
base_dir=$2
exp_name=$3
model_name=$4
dataset_base_path=$5
fixed_image=$6
mri_fixed_path=$7
subjs=$8
for i in $subjs; do subjects+=($i) ; done

############################################
########### Copy the generated images
############################################
model_name=$(basename "$(ls ${base_dir}/${exp_name}/checkpoint/top_model* 2>/dev/null | head -n 1)")

input_synthetic_path=${base_dir}_160/${exp_name}/sample_to_eval/${model_name}/normal_100
mkdir -p ${input_synthetic_path}/generated_images_working_dir

for subj in "${subjects[@]}"
do
echo "Copying the file: " ${subj}
cp ${input_synthetic_path}/${subj}.nii.gz ${input_synthetic_path}/generated_images_working_dir/${subj}_synth.nii.gz
done

############################################
############################################

# input: path to (synthetic) moving images
input_synthetic_path=${base_dir}_160/${exp_name}/sample_to_eval/${model_name}/normal_100/generated_images_working_dir

# output: path to warps
output_synthetic_path=${base_dir}/${exp_name}/sample_to_eval/${model_name}/normal_100/registration/${reg_method_type}/synthetic_modality
mkdir -p ${output_synthetic_path}
mkdir -p ${output_synthetic_path}/reg_files

# output: path to warped (orig modality) images
output_orig_path=${base_dir}/${exp_name}/sample_to_eval/${model_name}/normal_100/registration/${reg_method_type}/orig_modality
mkdir -p ${output_orig_path}
mkdir -p ${output_orig_path}/reg_files
mkdir -p ${output_orig_path}/labels

# register them and apply warp
bash registration_fireants.sh ${dataset_base_path} ${input_synthetic_path} ${output_synthetic_path} ${output_orig_path} ${fixed_image} ${mri_fixed_path} "${subjects[*]}"
