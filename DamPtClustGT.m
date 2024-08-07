% Clustering damaged points using Ground Truth Points
function result_clust_struct = DamPtClustGT(cur_damage_pts,org_gt_damaged_point_struct)
    result_clust_struct = struct;
	% clustering true positive detections
    % assign a clouster if the point is found in ground truth damaged clusters
    for itr = 1 : size(org_gt_damaged_point_struct,2)
        cur_gt_dmg_pts = org_gt_damaged_point_struct(itr).data;
        gt_centroid_vec(itr,:) = mean(cur_gt_dmg_pts);
        result_clust_struct(itr).data = [];
        cluster_bin = ismember(cur_damage_pts,cur_gt_dmg_pts,'rows');
        result_clust_struct(itr).data = cur_damage_pts(cluster_bin,:);
        cur_damage_pts(cluster_bin,:) = [];
    end
    % cluster all false positive points
    if size(cur_damage_pts,1) > 0
        % assign a cluster based on the summed distance from all TP points in a gt cluster
        for itr = 1 : size(cur_damage_pts,1) 
            norm_sum_dist_vec = [];
            for itr2 = 1 : size(result_clust_struct,2)
                cur_res_pts = result_clust_struct(itr2).data;
                pt_cluster_dist = sqrt(sum(((cur_res_pts - cur_damage_pts(itr,:)).^2),2));
                norm_sum_dist_vec(itr2) = sum(pt_cluster_dist)/size(cur_res_pts,1);
            end
            [~,min_idx] = min(norm_sum_dist_vec);
            cur_data = result_clust_struct(min_idx).data; % gt assignment to the point
            result_clust_struct(min_idx).data = [cur_data;cur_damage_pts(itr,:)]; % append to the list
        end
    end
end