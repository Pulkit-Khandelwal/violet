######## fireants-based-registration
input_path=$1
input_synthetic_path=$2
output_synthetic_path=$3
output_orig_path=$4
fixed_image=$5
mri_fixed_path=$6
subjs=$7
for i in $subjs; do subjects+=($i) ; done
mkdir -p ${output_orig_path}/labels

for subj in "${subjects[@]}"
do
    # Copy the orig exvivo so that we have the data in one place
    if [[ "$fixed_image" == "exvivo" ]]; then
    echo "fixed image is exvivo"
    c3d ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz -o ${output_orig_path}/${subj}_exvivo_mri.nii.gz
    else
    echo "fixed image is invivo"
    c3d ${mri_fixed_path}/${subj}_invivo_mri.nii.gz -o ${output_orig_path}/${subj}_invivo_mri.nii.gz
    fi
done


for subj in "${subjects[@]}"
do
    echo ${subj}
    python3 fireants_register.py ${subj} ${input_synthetic_path} ${mri_fixed_path} ${output_synthetic_path} ${output_orig_path}
    bash fireants_apply_transform.sh ${subj} ${input_synthetic_path} ${mri_fixed_path} ${output_synthetic_path} ${output_orig_path}
done
