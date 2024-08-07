% calculate the NN region and eigen values for a given set of parameters
function neighb_struct = KNNRadPF(ip_data,chunk_size,nn_rad_val)
    neighb_struct = struct;
    IPPCkdTreeMdl = KDTreeSearcher(ip_data);
    % if the number of points in th input are less than ignore Optimal NN determination
    ip_data_len = size(ip_data,1);
    if ip_data_len < 3 
        neighb_struct.data = zeros(3,3);
        neighb_struct.num_nn = 0; 
        neighb_struct.eig_val_vec = [];
        neighb_struct.normal_vec = [];
    else
        % extract the points in the region defined by the given radius
        for ip_pc_itr = 1 : ip_data_len
            indices = rangesearch(IPPCkdTreeMdl,ip_data(ip_pc_itr,:),nn_rad_val);
            indices_array = indices{1};
            nn_region_struct(ip_pc_itr).data = ip_data(indices_array,:);
        end
        % calculate eigen values for each extracted neighborhood
        chunk_vec = 0:chunk_size:ip_data_len;
        for chunk_itr = 0 : size(chunk_vec,2) - 1
            min_itr = chunk_itr*chunk_size + 1;
            max_itr = min(ip_data_len,(chunk_itr+1)*chunk_size);
            cur_struct = struct;
            cur_ct = 1; % counter for current temp struct generation
            for struct_itr = min_itr : max_itr
                cur_struct(cur_ct).data = nn_region_struct(struct_itr).data;
                cur_ct = cur_ct + 1;
            end
            neighb_struct_chunk = struct;
            parfor itr = 1 : max_itr - min_itr + 1
                temp_pts =  cur_struct(itr).data;
                neighb_struct_chunk(itr).data = temp_pts;
                if size(temp_pts,1) > 3
                    [~,nn_eig_val_vec,normal_vec] = ShapeFeat3D(temp_pts);
                    neighb_struct_chunk(itr).num_nn = size(temp_pts,1); % store the number of NNs    
                    neighb_struct_chunk(itr).eig_val_vec = nn_eig_val_vec; % store the shape vector
                    neighb_struct_chunk(itr).normal_vec = normal_vec; % store the normal vector
                else
                    neighb_struct_chunk(itr).num_nn = 0; 
                    neighb_struct_chunk(itr).eig_val_vec = []; 
                    neighb_struct_chunk(itr).normal_vec = [];
                end
            end % end of parfor for current chunk
            % combining individual chunk results for the entire dataset
            % combine entropy vectors
            cur_ct = 1; % counter for current struct
            for comb_itr  = min_itr : max_itr
                if isempty(fieldnames(neighb_struct))
                    neighb_struct = neighb_struct_chunk(cur_ct);
                else
                    neighb_struct(comb_itr) = neighb_struct_chunk(cur_ct);
                end
                cur_ct = cur_ct + 1;
            end
        end % end of data chunking
    end % end of conditional statement for input data size
    for itr = 1 : ip_data_len
        neighb_struct(itr).nn_rad_val = nn_rad_val; % save the current radius value
    end
end
