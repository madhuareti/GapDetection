function op_pts = RepeatRemove3DPF(pts)
    op_pts = [];
    % remove the repeating points
    % divide data into sections for parallel processing
    i = 1;
    vec_sep_factor = 10000; % number of values that are processed in each section
    while (i <= size(pts,1))
        j_vec = [];
        cur_up_val = 0;
        cur_dwn_val = 0;
        cur_pt = pts(i,:); % extract the current point
        while cur_up_val < size(pts,1) % iterate over data 
            cur_dwn_val = cur_up_val + i;
            cur_up_val = cur_dwn_val + vec_sep_factor; % value for upper index
            up_lim = min(cur_up_val, size(pts,1));
            temp_pts = pts(cur_dwn_val+1:up_lim,:); % sectioned data
            parfor j = 1 : size(temp_pts,1)
                if ((sum(cur_pt == temp_pts(j,:))) == 3)
                    j_vec = [j_vec,cur_dwn_val+j];
                end
            end
            pts(j_vec,:) = [];
        end
        i = i + 1 ;
    end
    op_pts = pts;
end