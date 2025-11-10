subj=$1
input_synthetic_path=$2
mri_fixed_path=$3
output_synthetic_path=$4
output_orig_path=$5

antsApplyTransforms -d 3 -n MultiLabel[0.5, 2] -i ${mri_fixed_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz \
-r ${input_synthetic_path}/${subj}_synth.nii.gz -t ${output_synthetic_path}/reg_files/${subj}_warp_smooth.nii.gz \
-o ${output_orig_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz
