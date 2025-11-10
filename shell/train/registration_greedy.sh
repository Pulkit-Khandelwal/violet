######## synthmorph-based-registration
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
 
    greedy -d 3 -rf ${input_synthetic_path}/${subj}_synth.nii.gz \
    -ri LINEAR \
    -rm ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz ${output_orig_path}/${subj}_exvivo_mri.nii.gz \
    -ri LABEL 0.2mm \
    -rm ${mri_fixed_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz ${output_orig_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz \

    # Moments matching
    greedy -d 3 \
    -i ${input_synthetic_path}/${subj}_synth.nii.gz ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz \
    -m NCC 3x3x3 -moments \
    -o ${output_synthetic_path}/reg_files/${subj}_moments.mat -threads 30

    # Affine
    greedy -d 3 -a -dof 12 \
    -i ${input_synthetic_path}/${subj}_synth.nii.gz ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz \
    -n 100x100x100 -m NCC 3x3x3 -ia ${output_synthetic_path}/reg_files/${subj}_moments.mat \
    -o ${output_synthetic_path}/reg_files/${subj}_affine.mat -threads 30

    # Deformable registration
    greedy -d 3 \
    -i ${input_synthetic_path}/${subj}_synth.nii.gz ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz \
    -it ${output_synthetic_path}/reg_files/${subj}_affine.mat -n 120x80x40 -m NCC 3x3x3 -sv \
    -o ${output_synthetic_path}/reg_files/${subj}_warp_smooth.nii.gz -threads 30

    # Apply warps
    greedy -d 3 -rf ${input_synthetic_path}/${subj}_synth.nii.gz \
    -ri LINEAR \
    -rm ${mri_fixed_path}/${subj}_exvivo_mri.nii.gz ${output_orig_path}/${subj}_exvivo_mri.nii.gz \
    -ri LABEL 0.2mm \
    -rm ${mri_fixed_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz ${output_orig_path}/labels/${subj}_exvivo_segm_label2vol.nii.gz \
    -r ${output_synthetic_path}/reg_files/${subj}_warp_smooth.nii.gz ${output_synthetic_path}/reg_files/${subj}_affine.mat -threads 30
done
