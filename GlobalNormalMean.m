% normal orientation, robust mean and global normal calculation
function [rob_normal, rob_mean, oriented_nrmls, plane_equa, tot_time] = GlobalNormalMean(ip_data,neighb_struct,ref_pt)
    tic;
    normal_vec_init = [];
    % Store Normal Vectors
    for data_itr = 1 : size(neighb_struct,2) % iterate over all input points
        neighb_struct_init(data_itr).optNN_pts = neighb_struct(data_itr).data;
        temp_normal_vec = neighb_struct(data_itr).normal_vec;
        if size(temp_normal_vec,1) > 0
            normal_vec_init(data_itr,:) = temp_normal_vec;
        else
            normal_vec_init(data_itr,:) = zeros(1,3);
        end
        clear temp_normal_vec;
    end
    clear neighb_struct;
    clear data_itr;
    tot_time = toc;
    % calculate global normal and the mean
    [rob_normal,rob_mean,oriented_nrmls, plane_equa, norm_calc_time] = ...
        RobustNrmlMean(ip_data, normal_vec_init, ref_pt);
    tot_time = tot_time + norm_calc_time;
end