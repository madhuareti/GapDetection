function surf_var_vec_complete = SurfVarPFV2(ip_point_cloud, neighb_struct_subset, chunk_size)
    surf_var_vec_complete = [];
     % break the data set into chunks of to limit memory overhead
    ip_data_len = size(ip_point_cloud,1);
    chunk_vec = 0:chunk_size:ip_data_len;
    for chunk_itr = 0 : size(chunk_vec,2) - 1
        min_itr = chunk_itr*chunk_size + 1;
        max_itr = min(ip_data_len,(chunk_itr+1)*chunk_size);
        cur_struct = struct;
        cur_ct = 1; % counter for current temp struct generation
        for struct_itr = min_itr : max_itr
            try
                cur_struct(cur_ct).num_nn = neighb_struct_subset(struct_itr).num_nn;
            catch
                ip_data_len
		nn_struct_size = size(neighb_struct_subset)
            end
            cur_struct(cur_ct).eig_val_vec = neighb_struct_subset(struct_itr).eig_val_vec;
%             cur_struct(cur_ct).num_nn = neighb_struct(struct_itr).num_nn;
            cur_ct = cur_ct + 1;
        end
        temp_ip_pc = ip_point_cloud(min_itr:max_itr,:);
        surf_var_vec_temp = [];
        parfor itr = 1 : size(temp_ip_pc,1)
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% changed logic from noise to
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%% undamaged from damaged
            % check if the NN region is empty based on previous arbritray assignments
            if cur_struct(itr).num_nn < 3 % points with less than 1 point in neighborhood, it is always classified as damage
                surf_var_vec_temp(itr,1) = 4; % assign a arbritarily large number
                continue; % go to the next iteration
            end
    %             if cur_struct(itr).num_nn == 0
    %                 surf_var_vec_temp(itr) = 4; % assign a arbritarily large number
    %                 continue; % go to the next iteration
    %             end
            % since negative eigen values are not possible, sum zero means all the eigen values are zeros
            if (sum(cur_struct(itr).eig_val_vec) == 0 ) 
                surf_var_vec_temp(itr,1) = 4; % assign a arbritarily large number
                continue; 
            end
            %% surface variation calculation
            surf_var_vec_temp(itr,1) = min(cur_struct(itr).eig_val_vec)/ sum(cur_struct(itr).eig_val_vec); 
        end % end of parfor
        % cummulative surface variation value vector
        surf_var_vec_complete = [surf_var_vec_complete;surf_var_vec_temp]; 
    end
    % end of SV value calculation
end
