function [damaged_points_res,max_entropy,thresh_value,time_elapsed,thresh_vec,surf_val_vec] = SVDamPtDetecNNipMaxEntrCuckooV4(ip_point_cloud,neighb_struct_subset,num_thresh,chunk_size)  
    damaged_points_res = []; % labeled damaged points     
    thresh_value = 0.4; % damaged point threshold (arbritarily large value)
    thresh_vec = thresh_value*ones(1, num_thresh); % vector with three segment threshold values
    surf_val_vec = []; % complete list of SV values
    time_elapsed = 0; % total time calculation
    max_entropy = 0; % maximum entropy value for segmented data
    %% Filter the NN regions based on eigen values and count
    % skip the value of SV for the folowing cases
    tic;
    if size(ip_point_cloud,1) < 3
        % when input < 3 == all points are labelled undamaged
        dmg_pt_bin = false(1,size(ip_point_cloud,1));
        max_entropy = -1;
        time_elapsed = toc;
    else
        %% SV value calculation
        surf_val_vec = SurfVarPFV2(ip_point_cloud, neighb_struct_subset, chunk_size);
        valid_surf_bin = surf_val_vec ~= 4;  % number of non arbritray SV values
        valid_surf_ct = sum(valid_surf_bin);
        valid_surf = surf_val_vec(valid_surf_bin);
        %% Threshold Value Calculation
        % when point cloud < 3 points == all classified as undamaged
        thresh_vec = thresh_value;
        if ~valid_surf_ct % stop analysis is no valid SV values
            % when all SV values are arbirtary, all classified as undamaged
            dmg_pt_bin = false(1,size(ip_point_cloud,1));
            max_entropy = -1;
            time_elapsed = toc;
        else 
            % Cuckoo Search
            max_iter = 40; % maximum number of iterations for the heuristic optimization
            num_sol = 80; % number of solutions calculated in each iteration
            max_rep = round(max_iter * 0.25); % termination condition based on repetation of optimal fitness of HO
            time_elapsed = toc;
            [best_nest,max_entropy,tot_time] = CuckooSearch(valid_surf,num_sol,num_thresh,max_iter,max_rep);
%             [best_nest,max_entropy,tot_time] = cuckoo_search(valid_surf',num_sol,num_thresh,max_iter,max_rep);
            thresh_value = best_nest(num_thresh); % choosing the second thresh value to label exclusive damaged points section
            thresh_vec = best_nest;
            dmg_pt_bin = (surf_val_vec >= thresh_value & surf_val_vec ~=4);
            time_elapsed = tot_time + time_elapsed; % Store the time for the intital process to save it for future iterations
        end % end of block for valid sv value analysis
    end % end of block for valid input analysis
    damaged_points_res = ip_point_cloud(dmg_pt_bin,:);
end