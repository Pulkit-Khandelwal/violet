###########################################################################
# reorient the postmortem and the corresponding antemortem MRI
# same orientation: LPI
# Resamples to the same dimensions and resolution 
###########################################################################

subjects=()
src_dir=/working_dir/files_warped
dst_dir=${src_dir}/for_translate
mkdir -p ${dst_dir}
mkdir -p ${dst_dir}/labels

for subj in "${subjects[@]}"
do

    c3d ${src_dir}/${subj}_invivo_mri_trimmed.nii.gz -resample-mm 1.2x1.2x1.2mm -stretch 0.1% 99.9% 0 1 -clip 0 1 -pad-to 160x160x160 0 -orient LPI -o ${dst_dir}/${subj}_invivo_mri.nii.gz
    c3d ${src_dir}/${subj}_invivo_segm_trimmed.nii.gz -int 3 -resample-mm 1.2x1.2x1.2mm -pad-to 160x160x160 0 -orient LPI -o ${dst_dir}/labels/${subj}_invivo_segm.nii.gz

    c3d ${src_dir}/${subj}_exvivo_registered_mri_affine.nii.gz -resample-mm 1.2x1.2x1.2mm -stretch 0.1% 99.9% 0 1 -clip 0 1 -pad-to 160x160x160 0 -orient LPI -o ${dst_dir}/${subj}_exvivo_mri.nii.gz
    c3d ${src_dir}/${subj}_exvivo_registered_segm_affine.nii.gz -int 3 -resample-mm 1.2x1.2x1.2mm -pad-to 160x160x160 0 -orient LPI -o ${dst_dir}/labels/${subj}_exvivo_segm.nii.gz

    ######## FreeSurfer-based resampling (used this for segm rather than greedy)
    mri_label2vol --seg ${src_dir}/${subj}_invivo_segm_trimmed.nii.gz \
    --temp ${dst_dir}/${subj}_invivo_mri.nii.gz \
    --o ${dst_dir}/labels/${subj}_invivo_segm_label2vol.nii.gz \
    --regheader ${src_dir}/${subj}_invivo_segm_trimmed.nii.gz

    mri_label2vol --seg ${src_dir}/${subj}_exvivo_registered_segm_affine.nii.gz \
    --temp ${dst_dir}/${subj}_exvivo_mri.nii.gz \
    --o ${dst_dir}/labels/${subj}_exvivo_segm_label2vol.nii.gz \
    --regheader ${src_dir}/${subj}_exvivo_registered_segm_affine.nii.gz

done
