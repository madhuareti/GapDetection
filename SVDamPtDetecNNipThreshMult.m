function [damaged_points,updated_pc,thresh_value,time_elapsed,surf_val_vec] = SVDamPtDetecNNipThreshMult(ip_data,neighb_struct_subset,ThrshMultFac,chunk_size)  
    damaged_points = []; % labeled damaged points     
    updated_pc = []; % undamaged points
    thresh_value = 0.4; % damaged point threshold (arbritarily large value)
    surf_val_vec = []; % complete list of SV values
    time_elapsed = 0; % total time calculation
    %% Filter the NN regions based on eigen values and count
    % skip the value of SV for the folowing cases
%     tic;
    if size(ip_data,1) < 3
        % when input < 3 == all points are labelled undamaged
        dmg_pt_bin = false(1,size(ip_data,1));
%         time_elapsed = toc;
    else
        %% SV value calculation
        surf_val_vec = SurfVarPFV2(ip_data, neighb_struct_subset, chunk_size);
        valid_surf_bin = surf_val_vec ~= 4;  % number of non arbritray SV values
        valid_surf_ct = sum(valid_surf_bin);
        valid_surf = surf_val_vec(valid_surf_bin);
        %% Threshold Value Calculation
        % when point cloud < 3 points == all classified as undamaged
        thresh_vec = thresh_value;
        if ~valid_surf_ct % stop analysis is no valid SV values
            % when all SV values are arbirtary, all classified as undamaged
            dmg_pt_bin = false(1,size(ip_data,1));
%             time_elapsed = toc;
        else 
            mean_sv = mean(valid_surf);
            std_sv = std(valid_surf);
            thresh_value = mean_sv + ThrshMultFac * std_sv;
%             time_elapsed = toc;
            dmg_pt_bin = (surf_val_vec >= thresh_value & surf_val_vec ~=4);
        end % end of block for valid sv value analysis
    end % end of block for valid input analysis
    damaged_points = ip_data(dmg_pt_bin,:);
    updated_pc = ip_data(~dmg_pt_bin,:);
end