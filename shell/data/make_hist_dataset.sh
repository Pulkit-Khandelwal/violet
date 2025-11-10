for HW in 160
do
    CT_name=$1
    MR_name=$2
    run_type=$3
    dataset_path=$4
    subjs=$5
    plane=$6
    save_hdf5_path=$7
    for i in $subjs; do subjs_list+=($i) ; done

    for which in ${run_type}
    do
        for hist_type in "normal"
        do
        python3 -u ../../brain_dataset_utils/generate_total_hist_global.py \
                --plane $plane \
                --hist_type $hist_type \
                --which_set $which \
                --height $HW \
                --width $HW \
                --pkl_name "${save_hdf5_path}/MR_hist_global_${HW}_${which}_${plane}_${hist_type}.pkl" \
                --CT_name $CT_name \
                --MR_name $MR_name \
                --dataset_path ${dataset_path} \
                --subjects_list "${subjs_list[@]}"              
        done       
    done
done      
