function [giou_val_vec,mean_giou_val,tot_time] = GeometricAnalysis(org_gt_damaged_point_struct,damaged_points_res,proj_normal,proj_mean)
    tic; % timer for the entire function
    %% Damaged Point Clustering based on 3D points
    result_clust_struct = DamPtClustGT(damaged_points_res,org_gt_damaged_point_struct);
    dmg_pt_ct = 0;
    for itr = 1 : size(result_clust_struct,2)
        cur_data = result_clust_struct(itr).data;
        dmg_pt_ct = dmg_pt_ct + size(cur_data,1);
    end
    if dmg_pt_ct ~= size(damaged_points_res,1)
        disp("Clustered Point Count doesn't match with Input Count")
    end
    %% Cluster Point Projection: GT and Result
    % elimate axes values based on the normal vector components
    [~,idx] = max(proj_normal); % for X axis 1st element is one all others zero. 
    idx_vec = 1:3;
    keep_idx = idx_vec((idx_vec-idx) ~= 0); % only preserve these coordinates
    res_pt_ct = 0;
    gt_pt_ct = 0;
    gt_dmg_pts = [];
    proj_res_clust = [];
    proj_gt_clust = [];
    gt_based_closest_clust_proj_strct = struct;
    for itr = 1 : size(result_clust_struct,2)
        cur_res_clust = result_clust_struct(itr).data;
        if size(cur_res_clust,1) > 3
          proj_res_clust_trans_temp = Proj32D(cur_res_clust,proj_mean,proj_normal,keep_idx);
        else
          proj_res_clust_trans_temp = [];
        end
        gt_based_closest_clust_proj_strct(itr).res_data = proj_res_clust_trans_temp;
        proj_res_clust = [proj_res_clust;proj_res_clust_trans_temp];
        cur_gt_clust = org_gt_damaged_point_struct(itr).data;
        gt_dmg_pts = [gt_dmg_pts;cur_gt_clust];
        if size(cur_gt_clust,1) > 3
          proj_gt_clust_trans_temp = Proj32D(cur_gt_clust,proj_mean,proj_normal,keep_idx);
        else
          proj_gt_clust_trans_temp = [];
        end
        gt_based_closest_clust_proj_strct(itr).gt_data = proj_gt_clust_trans_temp;
        proj_gt_clust = [proj_gt_clust;proj_gt_clust_trans_temp];
    end
    gt_clust_proj_struct.ip_data = gt_dmg_pts;
    gt_clust_proj_struct.proj_data = proj_gt_clust;
    gt_clust_proj_struct.keep_idx = keep_idx;
    result_clust_proj_struct.ip_data = damaged_points_res;
    result_clust_proj_struct.proj_data = proj_res_clust;
    result_clust_proj_struct.keep_idx = keep_idx;
    %% Determine correspondence between the ground truth and result clusters based on distance between the centroids
%     [~,closest_cluster_proj_strct] = ClstrCoresGTRes(ground_truth_clust_strct,result_clust_strct,gt_clust_proj_strct,result_clust_proj_strct);
    closest_cluster_proj_strct = gt_based_closest_clust_proj_strct;
    %% GIoU Calculation
    giou_val_vec = GIouIdx(closest_cluster_proj_strct);
    mean_giou_val = mean(giou_val_vec);
    tot_time = toc;
end