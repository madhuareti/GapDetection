%% need to change the logic for multiple GT correspondences
%% Determine Corresponding Clusters for Damaged Result within Ground Truth Cluster
function [closest_cluster_strct,closest_cluster_proj_strct] = ClstrCoresGTRes(ground_truth_clust_strct,result_clust_strct,gt_clust_proj_strct,result_clust_proj_strct)
%% Cluster Correspondence Using 3D data
    % cluster distance calculation
    % Centroid Calculation for clusters 
    gt_centroid_vec = [];
    rslt_centroid_vec = [];
    for itr = 1 : size(ground_truth_clust_strct,2)
        if size(ground_truth_clust_strct(itr).data,1) > 0
            gt_centroid_vec(itr,:) = mean(ground_truth_clust_strct(itr).data);
        else
            gt_centroid_vec(itr,:) = [0,0,0];
        end
    end
    for itr = 1 : size(result_clust_strct,2)
        if size(result_clust_strct(itr).data,1) > 0
            rslt_centroid_vec(itr,:) = mean(result_clust_strct(itr).data);
        else
            rslt_centroid_vec(itr,:) = [0,0,0];
        end
    end
    res_gt_centroid_dist_mat = ProximityMat(rslt_centroid_vec,gt_centroid_vec);
    % reassign distances for filler indices - number of clusters in GT and result 
    for itr = 1 : size(res_gt_centroid_dist_mat,1)
        % when the gt has no points in a cluster
        if sum(gt_centroid_vec(itr,:)) == 0 
            res_gt_centroid_dist_mat(:,itr) = -1*ones(size(res_gt_centroid_dist_mat,1),1);
        end
        % when the result has no points in a cluster
        if sum(rslt_centroid_vec(itr,:)) == 0
            res_gt_centroid_dist_mat(itr,:) = -1*ones(1,size(res_gt_centroid_dist_mat,1));
        end
    end
    % define result cluster idx, gt cluster idx, distance between centroids
    closest_cluster_vec = zeros(size(res_gt_centroid_dist_mat,1),3); 
    for itr = 1 : size(res_gt_centroid_dist_mat,1)
        closest_cluster_vec(itr,1) = itr; % result cluster index
        temp_vec = res_gt_centroid_dist_mat(itr,:); % extract distance from all the centroids to the cur centroid point
        [match_dist,match_idx] = min(temp_vec(temp_vec >= 0));
        if size(match_dist,1) > 0 % if a correspoing GT cluster exists
            closest_cluster_vec(itr,2) = match_idx;
            closest_cluster_vec(itr,3) = match_dist;
        else % if no points in a GT cluster are found 
            closest_cluster_vec(itr,2) = -1;
            closest_cluster_vec(itr,3) = 0;
        end
    end
    %% Checking if both paired cluster agree with the correspondence
    % attempt to reassign clusters with the multiple assignments
    for itr = 1 : size(closest_cluster_vec,1)
        cur_cluster_match = closest_cluster_vec(itr,2); % gt idx
        % skip result clusters where no GT clusters are asssigned 
        if cur_cluster_match < 0 % (based on logic assignment in the previous loop)
            continue
        end
        % check if more than 1 assignment for the cur GT cluster
        same_clust_match_bin = (cur_cluster_match == closest_cluster_vec(:,2));
        if sum(same_clust_match_bin) > 1
            % find the index of 1s in the binary vector
            bin_vec_idx = find(same_clust_match_bin);
            % extract distances of the res clusters to cur. GT cluster
            bin_vec_dist_vec = closest_cluster_vec(bin_vec_idx,3); % result
            % exclude the cluster with least dist and reassign for rest
            [~,opt_idx] = min(bin_vec_dist_vec); % best result for cur gt
            bin_vec_idx(opt_idx) = []; 
            % extract dist to GT cluster for rest of result clusters
            for itr2 = 1 : size(bin_vec_idx,1)
                % current result and all GT centroid distance extract
                cur_temp_dist_vec = res_gt_centroid_dist_mat(bin_vec_idx(itr2),:); % all gts for current result
                cur_temp_dist_vec(cur_cluster_match) = []; % delete the current gt clust distance entry
                [match_dist,match_idx] = min(temp_vec(cur_temp_dist_vec >= 0));
                if size(match_dist,1) > 0 % if a correspoing GT cluster exists
                    closest_cluster_vec(bin_vec_idx(itr2),2) = match_idx;
                    closest_cluster_vec(bin_vec_idx(itr2),3) = match_dist;
                else % if no points in a GT cluster are found reassign it to cur gt cluster
                    % don't change anything
                end
            end
        end
    end
    %% combining the pairs having the same correspondence in GT
    % GT and Result Cluster Mapping Structure - 3D Data
    closest_cluster_strct = struct;
    for itr = 1 : size(closest_cluster_vec,1)
        idx2 = closest_cluster_vec(itr,2);
        closest_cluster_strct(itr).gt_data = ground_truth_clust_strct(idx2).data;
        res_data = [];
        cur_idx_bin = (closest_cluster_vec(:,2) == idx2);
        res_match_idx = find(cur_idx_bin);
        for itr2 = 1 : size(res_match_idx,1)  
            idx1 = closest_cluster_vec(res_match_idx,1);
            res_data = [res_data;result_clust_strct(idx1).data];
        end
        closest_cluster_strct(itr).res_data = res_data;
    end
    %% Clustering Projected Point Cluster Data
    gt_ip_data = gt_clust_proj_strct.ip_data;
    gt_proj_data = gt_clust_proj_strct.proj_data;
    res_ip_data = result_clust_proj_strct.ip_data;
    res_proj_data = result_clust_proj_strct.proj_data;
    closest_cluster_proj_strct = struct;
    for itr =  1 : size(closest_cluster_vec,1)
        gt_clust_proj = []; % cur 2d gt cluster
        res_clust_proj = []; % cur 2d res cluster
        gt_data = closest_cluster_strct(itr).gt_data; % current 3d gt cluster
        res_data = closest_cluster_strct(itr).res_data; % current 3d res cluster
        for itr2 = 1 :  size(gt_data,1)
           cur_pt_org_idx = ismember(gt_ip_data,gt_data(itr2,:),'rows');
           gt_clust_proj(itr2,:) = gt_proj_data(cur_pt_org_idx,:);
        end
        for itr2 = 1 :  size(res_data,1)
           cur_pt_org_idx = ismember(res_ip_data,res_data(itr2,:),'rows');
           res_clust_proj(itr2,:) = res_proj_data(cur_pt_org_idx,:);
        end
        closest_cluster_proj_strct(itr).gt_data = gt_clust_proj;
        closest_cluster_proj_strct(itr).res_data = res_clust_proj;
    end
end