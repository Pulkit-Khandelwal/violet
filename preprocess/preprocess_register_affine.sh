
###########################################################################
# Register the postmortem t2w to the corresponding invivo MRI
# label-based affine registration
###########################################################################
subjects=()

####### ex vivo mri+segm
exvivo_mri_dir=
exvivo_segm_dir=

####### in vivo mri+segm
invivo_dir_mri=
invivo_dir_segm=

####### working directory
work_dir=
mkdir -p ${work_dir}
mkdir -p ${work_dir}/files_warped

for subj in "${subjects[@]}"
do
    echo ${subj}

    # This is just some quick logic (depending upon how our files were named)
    # to check if the postmortem hemisphere imaged is left or right
    subj_exvivo=${subj}R
    exvivo_mri=${exvivo_mri_dir}/${subj_exvivo}_t2w_0000.nii.gz
    exvivo_segm_orig=${exvivo_segm_dir}/${subj_exvivo}_t2w.nii.gz

    if [ -f "$exvivo_mri" ]; then
    echo "this is right hemis"
    side=R

    else
    echo "this is left hemis"
    side=L
    subj_exvivo=${subj}L
    exvivo_mri=${exvivo_mri_dir}/${subj_exvivo}_t2w_0000.nii.gz
    exvivo_segm_orig=${exvivo_segm_dir}/${subj_exvivo}_t2w.nii.gz
    fi
    
    subject=subject_${subj}${side}
    mkdir -p ${work_dir}/${subject}

    # clean the exvivo segmentation by retaining the largest CC for each label and then merging them
    cp ${exvivo_segm_orig} ${work_dir}/${subject}/${subj}_exvivo_segm_orig.nii.gz
    c3d ${work_dir}/${subject}/${subj}_exvivo_segm_orig.nii.gz -replace 6 7 -o ${work_dir}/${subject}/${subj}_exvivo_segm_orig.nii.gz

    ##### Lets get the CC for each label and then merge it
    base_file=${work_dir}/${subject}/${subj}_exvivo_segm_orig.nii.gz
    numlabel_array=(1 2 3 4 5 7 8 9 10)
    for numlabel in "${numlabel_array[@]}"
    do
    echo "CC for label " ${numlabel}
        c3d ${base_file} -retain-labels ${numlabel} -replace ${numlabel} 1 -comp -threshold 1 1 1 0 -replace 1 ${numlabel} -o ${work_dir}/${subject}/${subj}_label_${numlabel}_cc.nii.gz
    done

    c3d ${work_dir}/${subject}/${subj}_label_1_cc.nii.gz ${work_dir}/${subject}/${subj}_label_2_cc.nii.gz ${work_dir}/${subject}/${subj}_label_3_cc.nii.gz \
    ${work_dir}/${subject}/${subj}_label_4_cc.nii.gz ${work_dir}/${subject}/${subj}_label_5_cc.nii.gz ${work_dir}/${subject}/${subj}_label_7_cc.nii.gz \
    ${work_dir}/${subject}/${subj}_label_8_cc.nii.gz ${work_dir}/${subject}/${subj}_label_9_cc.nii.gz ${work_dir}/${subject}/${subj}_label_10_cc.nii.gz \
    -add -add -add -add -add -add -add -add -o ${work_dir}/${subject}/${subj}_exvivo_segm_cleaned.nii.gz

    echo "CC obtained for each label and merged to get a nicer segmentation with no erroneous segmentation labels hanging around"
    c3d ${work_dir}/${subject}/${subj}_exvivo_segm_cleaned.nii.gz -dup -lstat

    exvivo_segm=${work_dir}/${subject}/${subj}_exvivo_segm_cleaned.nii.gz

    if [[ $side == "R" ]]; then
        FS_LABELS="41 42 49 50 51 52 53 54"
        FS_GM="42 53"
        FS_WM="41 49 50 51 52 54"
    else 
        FS_LABELS="2 3 10 11 12 13 17 18"
        FS_GM="3 17"
        FS_WM="2 10 11 12 13 18"
    fi

    ###### Postmortem
    # Extract GM and WM-plus from postmortem deep learning segmentation
    c3d ${exvivo_segm} -retain-labels 1 10 -binarize -smooth-fast 0.4mm -resample-mm 1.0mm -type uchar ${work_dir}/${subject}/exvivo_segm_gm_ds.nii.gz
    c3d ${exvivo_segm} -retain-labels 2 3 4 5 7 9 -binarize -smooth-fast 0.4mm -resample-mm 1.0mm -type uchar ${work_dir}/${subject}/exvivo_segm_wmplus_ds.nii.gz

    ###### Antemortem
    invivo_mri=${invivo_dir_mri}/${subj}.nii.gz
    invivo_segm=${invivo_dir_segm}/${subj}_synthseg.nii.gz

    # Extract GM and WM-plus from antemortem deep learning segmentation
    c3d ${invivo_segm} -retain-labels ${FS_LABELS} -type uchar -o ${work_dir}/${subject}/invivo_segm_hemis.nii.gz
    c3d ${invivo_segm} -retain-labels ${FS_GM} -binarize -trim 5mm -type uchar -o ${work_dir}/${subject}/invivo_segm_gm.nii.gz
    c3d ${invivo_segm} -retain-labels ${FS_WM} -binarize -trim 5mm -type uchar -o ${work_dir}/${subject}/invivo_segm_wmplus.nii.gz

    # Retain the correct hemisphere for invivo
    c3d ${work_dir}/${subject}/invivo_segm_hemis.nii.gz -binarize ${invivo_mri} -multiply -o ${work_dir}/${subject}/invivo_mri_hemis.nii.gz

    # Copy all the required files
    cp ${work_dir}/${subject}/invivo_mri_hemis.nii.gz ${work_dir}/files_warped/${subj_exvivo}_invivo_mri.nii.gz
    cp ${work_dir}/${subject}/invivo_segm_hemis.nii.gz ${work_dir}/files_warped/${subj_exvivo}_invivo_segm.nii.gz
    cp ${invivo_mri} ${work_dir}/files_warped/${subj_exvivo}_invivo_mri_orig.nii.gz
    cp ${invivo_segm} ${work_dir}/files_warped/${subj_exvivo}_invivo_segm_orig.nii.gz

    cp ${exvivo_mri} ${work_dir}/files_warped/${subj_exvivo}_exvivo_mri_orig.nii.gz
    cp ${exvivo_segm} ${work_dir}/files_warped/${subj_exvivo}_exvivo_segm_orig.nii.gz

    ################################################################################################################################
    ######## label-based affine registration
    # Perform moments matching and affine registration
    greedy -d 3 \
    -i ${work_dir}/${subject}/invivo_segm_gm.nii.gz ${work_dir}/${subject}/exvivo_segm_gm_ds.nii.gz \
    -i ${work_dir}/${subject}/invivo_segm_wmplus.nii.gz ${work_dir}/${subject}/exvivo_segm_wmplus_ds.nii.gz \
    -m NCC 2x2x2 -moments \
    -o ${work_dir}/${subject}/moments.mat

    greedy -d 3 -a -dof 12 \
    -i ${work_dir}/${subject}/invivo_segm_gm.nii.gz ${work_dir}/${subject}/exvivo_segm_gm_ds.nii.gz \
    -i ${work_dir}/${subject}/invivo_segm_wmplus.nii.gz ${work_dir}/${subject}/exvivo_segm_wmplus_ds.nii.gz \
    -n 100x50x10 -m NCC 2x2x2 -ia ${work_dir}/${subject}/moments.mat \
    -o ${work_dir}/${subject}/affine.mat

    # Let's warp the images to the trimmed version of the invivo mri
    c3d ${work_dir}/${subject}/invivo_mri_hemis.nii.gz -trim 30vox -o ${work_dir}/${subject}/invivo_mri_hemis_trimmed.nii.gz
    c3d ${work_dir}/${subject}/invivo_segm_hemis.nii.gz -trim 30vox -o ${work_dir}/${subject}/invivo_segm_hemis_trimmed.nii.gz

    cp ${work_dir}/${subject}/invivo_mri_hemis_trimmed.nii.gz ${work_dir}/files_warped/${subj_exvivo}_invivo_mri_trimmed.nii.gz
    cp ${work_dir}/${subject}/invivo_segm_hemis_trimmed.nii.gz ${work_dir}/files_warped/${subj_exvivo}_invivo_segm_trimmed.nii.gz

    # warp conformed exvivo segm and mri
    greedy -d 3 -rf ${work_dir}/${subject}/invivo_mri_hemis_trimmed.nii.gz \
    -ri LINEAR \
    -rm ${exvivo_mri} ${work_dir}/files_warped/${subj_exvivo}_exvivo_registered_mri_affine.nii.gz \
    -ri LABEL 0.2vox \
    -rm ${exvivo_segm} ${work_dir}/files_warped/${subj_exvivo}_exvivo_registered_segm_affine.nii.gz \
    -r ${work_dir}/${subject}/affine.mat

done
