for HW in 160
do
    CT_name=$1
    MR_name=$2
    run_type=$3
    dataset_path=$4
    save_hdf5_path=$5
    is_test=$6
    plane=$7
    subjs=$8
    echo $plane
    for i in $subjs; do subjs_list+=($i) ; done
    
        for which in ${run_type}
        do
            python3 -u ../../brain_dataset_utils/generate_total_hdf5_csv.py \
                    --plane $plane \
                    --which_set $which \
                    --height $HW \
                    --width $HW \
                    --hdf5_name "${save_hdf5_path}/${HW}_${which}_${plane}.hdf5" \
                    --CT_name $CT_name \
                    --MR_name $MR_name \
                    --dataset_path $dataset_path \
                    --is_test_set ${is_test} \
                    --subjects_list "${subjs_list[@]}"    
        done
done      
