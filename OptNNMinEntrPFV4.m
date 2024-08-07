function neighb_struct = OptNNMinEntrPFV4(ip_point_cloud,IPPCkdTreeMdl, NNRad_vec, chunk_size)
    neighb_struct = struct;
    % if the number of points in th input are less than ignore Optimal NN determination
    ip_data_len = size(ip_point_cloud,1);
    if ip_data_len < 3 
        neighb_struct_temp = struct;    
        neighb_struct_temp.data = zeros(3,3);
        neighb_struct_temp.num_nn = 0; 
        neighb_struct_temp.eig_val_vec = [];
        neighb_struct_temp.nn_entrp_val = 4;% arbritrary value
        neighb_struct.data = neighb_struct_temp;
    else
%         loop_ct = 1; % counter to iniatate the fieldnames for NN storage
        nn_entropy_vec = []; % save the entropy of each point
        neighb_struct_temp2 = struct; % storage for all points and all Radii
        nn_idx_struct = struct; % store for all NN radii and points
        for nn_mult_itr = 1 : size(NNRad_vec,1)
            neighb_struct_temp = struct; % storage for all points one radii
            temp_nn_entrpy = []; % storage for entropy values for one radius
            nn_rad_temp = NNRad_vec(nn_mult_itr); % determine the NN radius
            indices_array_struct = struct; % structure to store NN point indices
            nn_idx_struct_temp = struct; % structure to store NN point indices
            for ip_pc_itr = 1 : ip_data_len
                indices = rangesearch(IPPCkdTreeMdl,ip_point_cloud(ip_pc_itr,:),nn_rad_temp);
                indices_array = indices{1};
                nn_idx_struct_temp(ip_pc_itr).data = indices_array;
                indices_array_struct(ip_pc_itr).data = ip_point_cloud(indices_array,:);
            end
            nn_idx_struct(nn_mult_itr).data = nn_idx_struct_temp;
            % free up memory
            clear nn_idx_struct_temp;
            clear indices;
            % break the data set into chunks of to limit memory overhead
            chunk_vec = 0:chunk_size:ip_data_len;
            for chunk_itr = 0 : size(chunk_vec,2) - 1
                min_itr = chunk_itr*chunk_size + 1;
                max_itr = min(ip_data_len,(chunk_itr+1)*chunk_size);
                cur_struct = struct;
                cur_ct = 1; % counter for current temp struct generation
                for struct_itr = min_itr : max_itr
                    cur_struct(cur_ct).data = indices_array_struct(struct_itr).data;
                    cur_ct = cur_ct + 1;
                end
                nn_entrp_val_vec = zeros(max_itr - min_itr + 1, 1); % save the entropy for the current points
                neighb_struct_chunk = struct;
                parfor ip_pc_itr = 1 : max_itr - min_itr + 1
                    nn_entr_nrml = []; % normal vector 
                    nn_eig_val_vec = []; % eigen value vector 
                    nn_entrp_val = 0;
                    % conduct the analysis only if points are detected in the input radius
                    temp_pts =  cur_struct(ip_pc_itr).data;
                    if size(temp_pts,1) > 3 
                        % NN region entropy calculation 
                        [nn_entrp_val,nn_eig_val_vec,nn_entr_nrml] = ShapeFeat3D(temp_pts);
                        neighb_struct_chunk(ip_pc_itr).data = temp_pts;
                        if nn_entrp_val == 4  || nn_entrp_val < 0.00001 % All eigen values of covariance matrix = 0
                            neighb_struct_chunk(ip_pc_itr).data = zeros(3,3);
                            neighb_struct_chunk(ip_pc_itr).num_nn = 0; 
                            neighb_struct_chunk(ip_pc_itr).eig_val_vec = [];
                            neighb_struct_chunk(ip_pc_itr).nn_entrp_val = 4;% arbritrary value
                            neighb_struct_chunk(ip_pc_itr).normal_vec = [];
                            nn_entrp_val_vec(ip_pc_itr,1) = 4;
                        else
                            neighb_struct_chunk(ip_pc_itr).num_nn = size(temp_pts,1); % store the number of NNs    
                            neighb_struct_chunk(ip_pc_itr).eig_val_vec = nn_eig_val_vec; % store the shape vector
                            neighb_struct_chunk(ip_pc_itr).nn_entrp_val = nn_entrp_val;
                            neighb_struct_chunk(ip_pc_itr).normal_vec = nn_entr_nrml';
                            if nn_entrp_val < 4 % More than 2 Points are present in the NN
                                   nn_entrp_val_vec(ip_pc_itr,1) = nn_entrp_val;
                            else % Less than 3 points in the NN
                                nn_entrp_val_vec(ip_pc_itr,1) = 4;% arbritrary value
                            end
                        end
                        temp_pts = []; % clearing some space for each worker
                    else
                        neighb_struct_chunk(ip_pc_itr).data = zeros(3,3);
                        neighb_struct_chunk(ip_pc_itr).num_nn = 0; 
                        neighb_struct_chunk(ip_pc_itr).eig_val_vec = [];
                        neighb_struct_chunk(ip_pc_itr).nn_entrp_val = 4;% arbritrary value
                        neighb_struct_chunk(ip_pc_itr).normal_vec = [];
                        nn_entrp_val_vec(ip_pc_itr,1) = 4;
                    end
                end %% end of parfor loop
                % combining individual chunk results for the entire dataset
                % combine entropy vectors
                temp = [temp_nn_entrpy;nn_entrp_val_vec]; % temp assign.
                temp_nn_entrpy = temp;
                cur_ct = 1; % counter for current struct
                for comb_itr  = min_itr : max_itr
                    if isempty(fieldnames(neighb_struct_temp))
                        neighb_struct_temp= neighb_struct_chunk(cur_ct);
                    else
                        neighb_struct_temp(comb_itr) = neighb_struct_chunk(cur_ct);
                    end
                    cur_ct = cur_ct + 1;
                end
            end %% end of data segmentation loop
            neighb_struct_temp2(nn_mult_itr).data = neighb_struct_temp;
            nn_entropy_vec(:,nn_mult_itr) = temp_nn_entrpy;
            % delete all the data storage variables
            clear neighb_struct_chunk;
            clear cur_struct;
            clear nn_entrp_val_vec;
            clear temp_nn_entrpy;
            clear temp;
            clear temp_pts;
            clear nn_entr_nrml; 
            clear nn_eig_val_vec; 
            clear nn_entrp_val;
        end %% end of NN region for all radii and all points
        % free up memory
        clear ip_point_cloud; 
        clear IPPCkdTreeMdl;
        opt_neighb_struct_temp = struct;
        %% Extract the min entropy NN region for each point considering all Radii outputs
        % extract NN radius values based on min entropy
        [min_entr_vec,vec_pt_max_entrpy_idx] = min(nn_entropy_vec,[],2);
        clear nn_entropy_vec;
        % break the data set into chunks of 1000 to limit memory
        % overhead 
        chunk_vec = 0:chunk_size:ip_data_len;
        opt_idx_struct = struct; % save indexes of points in the NN
        % initiate the variable for easy assignment inside the
        % parforloop. values wiil be overridden inside the loop
        for chunk_itr = 1 : size(chunk_vec,2) + 1
            min_itr = (chunk_itr - 1)*chunk_size + 1;
            max_itr = min(ip_data_len,chunk_itr*chunk_size);
            cur_struct = struct;
            for cur_ct = 1 : size(NNRad_vec,1)
                temp_struct = neighb_struct_temp2(cur_ct).data; % one NN value result
                cur_struct(cur_ct).data = temp_struct(min_itr:max_itr); % current chunk result for one NN value
            end
            if min_itr == 1 % struct intialization
                opt_neighb_struct_temp = temp_struct(1);
                opt_neighb_struct_temp.nn_rad = 1; % arbritrary
                opt_neighb_struct_temp.nn_idx = 1; % arbritrary
            end
            for full_data_pts_itr = min_itr : max_itr
                min_entr_cur = min_entr_vec(full_data_pts_itr);
                cur_pt_max_entrpy_idx = vec_pt_max_entrpy_idx(full_data_pts_itr);
                if min_entr_cur ~= 4 % extract data if entropy is not arbritrary
                    chunk_data_itr = full_data_pts_itr - min_itr + 1; % find the data index in the current chunk
                    cur_opt_cluster_temp = cur_struct(cur_pt_max_entrpy_idx).data;
                    cur_opt_cluster = cur_opt_cluster_temp(chunk_data_itr);
                    cur_opt_cluster.nn_rad = NNRad_vec(cur_pt_max_entrpy_idx);
                    % extract the all NN idXs for the opt. radius value
                    temp_struct = nn_idx_struct(cur_pt_max_entrpy_idx).data ;
                    % extract indices vector for all NN points in the radius
                    cur_opt_cluster.nn_idx = temp_struct(full_data_pts_itr).data;
                    opt_neighb_struct_temp(full_data_pts_itr) = cur_opt_cluster;
                end % end of conditional block checking for entropy
            end % end of for loop
        end
        neighb_struct.data = opt_neighb_struct_temp;
    end
end
