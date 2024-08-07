function [rob_normal, rob_mean, oriented_nrmls, plane_equa, tot_time] = RobustNrmlMean(org_ip_pc, normal_vec_init, ref_nrml_pt)
    tic; % timer for the entire function
    %% PC Projection Plane Estimation
    % Inverse Repartition to define a Robust Centroid
    % Narváez, E. A. L., & Narváez, N. E. L. (2006, February). Point cloud denoising using robust principal component analysis. In GRAPP (pp. 51-58).
    org_mean = mean(org_ip_pc);
    weight_vec = ones(size(org_ip_pc,1),1);
    dist_vec = ones(size(org_ip_pc,1),1);
    for itr = 1 : size(org_ip_pc,1)
        dist_vec(itr,1) =  sqrt(sum((org_mean-org_ip_pc(itr,:)).^2));
    end
    sum_dist_mean = sum(dist_vec);
    if sum_dist_mean
        for itr = 1 : size(org_ip_pc,1)
            if dist_vec(itr,1) ~= 0
                weight_vec(itr,1) =  1/(dist_vec(itr,1)*sum_dist_mean);
            end
        end
    end
    sum_weights = sum(weight_vec);
    weigh_sum_pt = [0,0,0];
    for itr = 1 : size(org_ip_pc,1)
        weigh_sum_pt = weigh_sum_pt + org_ip_pc(itr,:).*weight_vec(itr);
    end
    upd_mean_wghtd = weigh_sum_pt/sum_weights;
    clear weigh_sum_pt;
    clear dist_vec;
    clear sum_dist_mean;
    clear org_mean;
    clear itr;
    % retrieve the normal vector calculated in the initial iteration (normal_vec_init)
    % estimate the best projection plane normal by minimizing WRMSE of angle between normals
    % Align all the point normals in direction of reference point]
    oriented_nrmls = OrientVec(org_ip_pc, normal_vec_init, ref_nrml_pt);
    best_plane_normal = OptPCNormRMSE(org_ip_pc, oriented_nrmls, weight_vec, sum_weights);
    % align PCA vectors 1 and 2 as well
    % Define plane passing through centroid and normal as determined
    plane_equa_const = -best_plane_normal*upd_mean_wghtd';
    plane_equa = [best_plane_normal,plane_equa_const];
    rob_normal = best_plane_normal;
    rob_mean = upd_mean_wghtd;
    tot_time = toc;
end