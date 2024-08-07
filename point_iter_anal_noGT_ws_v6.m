clear;
clc;
close all;
%% Parameters
num_thresh = 2; % bi-level thresholding
NNMultiFactor_prev_iter_pts = 1; % constant to refine the damage labeled points
num_iter = 100; % number of iterations to be performed
 if ~isempty(gcp('nocreate'))
    delete(gcp('nocreate'));
 end
 try
   p = parcluster('local');
   parpool(p,feature('numcores'));
 catch Err
   disp('parpool intialization failed, quitting matlab');
   quit; % quitting matlab if fails
 end
% defining if linux or windows for "/" or "\" usage
slash_key = 'linux';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
rdrive_str = "/run/user/128000411/gvfs/smb-share:server=coe-fs.engr.tamu.edu,share=research/MEEN/Hasnain_Zohaib/Students/Areti_Madhu_Dhana/GapDetection/3d_point_cloud_geometry/GapDetect/";
local_str = "/home/staff/m/mareti/matlab_ws/GapDetect/";
sample_tag = "";
% dir_data_str = strcat("data",slsh,"disaster_city",slsh,"sample_data_complete_1007",slsh);
dir_data_str = strcat("data",slsh,"disaster_city",slsh,"raw_data_complete",slsh,"oriented_xyz",slsh);
save_str_init = strcat("results",slsh,"oriented_xyz_0224",slsh);
ip_str = strcat(local_str,dir_data_str)
rect_wall_thick = 4*2.54; % 4inch thick panels
% num_vals_vec = 20;
num_vals_vec = 20;
rad_range_vec = 0.25:0.15:1.25;
chunk_size = 5000; % chunk size for data division for parallel processing
min_rad_val = min(rad_range_vec);
max_rad_val = max(rad_range_vec);
clear rad_range_vec
% extract all the samples in a directory
del_keys = [".";".."];
dir_strs_temp = dir(fullfile(ip_str));
dir_strs = dir_strs_temp(~cellfun(@(x) MatchKeys(x, del_keys), {dir_strs_temp.name})); % paths of all directories (unique datasets)
dir_strs_bin = cellfun(@(x) MatchKeys(x,sample_tag), {dir_strs.name});
dir_strs_bin2 = find(dir_strs_bin);
dir_strs = dir_strs(dir_strs_bin2);
%dir_strs = dir_strs(dir_strs_bin)
if size(dir_strs,1) < 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
%% Steps
% 1- neighborhood time
% 2- cuckoo search and labeling
% 3- Damage Point Refinement Step
% iterate over all the data files found in a directory
data_list = dir_strs;
ip_sample_itr = 0;
while(ip_sample_itr <= size(dir_strs,1))
    ip_sample_itr = ip_sample_itr+1;
%     change env variable for matlab crash accomodation
    system("sed -i '/DIR_ITR/d' ~/.bashrc");
    command = strcat("echo export DIR_ITR=",string(ip_sample_itr)," >> ~/.bashrc");
    system(command);
    cur_ip_dir_str = strcat(dir_strs(ip_sample_itr).folder,slsh,dir_strs(ip_sample_itr).name);
    if isfolder(cur_ip_dir_str)
        data_list = dir(fullfile(cur_ip_dir_str,'*.mat')); 
        sample_tag_temp = split(cur_ip_dir_str,ip_str);
        sample_tag_temp2 = split(sample_tag_temp{2},"sample_");
        sample_tag = replace(sample_tag_temp{2},slsh,"");
    else % when looking at DP samples
	cur_ip_dir_str = dir_strs(ip_sample_itr).folder; 
        sample_tag_temp = split(data_list(ip_sample_itr).name,'.');	
        save_str1 = strcat(save_str_init,sample_tag,slsh);
        ip_sample_itr = size(dir_strs,1) + 1;
    end
    size(data_list,1)
    % iterate over all the samples within a data directory
    for ip_data_dir_itr = 12 : size(data_list,1)
	    % change env variable for matlab crash accomodation
        system("sed -i '/DATA_ITR/d' ~/.bashrc");
        command = strcat("echo export DATA_ITR=",string(ip_data_dir_itr)," >> ~/.bashrc");
        system(command);
	    %% load data
	    file_name_temp = split(data_list(ip_data_dir_itr).name,'.');
        file_name = file_name_temp(1);
        save_str = strcat(local_str, save_str1,file_name,slsh);
	    if isfolder(save_str)
	        continue;
	    end
	    ip_data_str_pc = strcat(cur_ip_dir_str,slsh,file_name,".mat")
	try
	   load(ip_data_str_pc);
	catch
	   continue;
	end
        try
            org_ip_pc = filter_pc; % 0.01m panel data
        catch
            org_ip_pc = cartographic_result; % this is for DP sample analysis
            clear cartographic_result;
        end
        clear file_name_temp;
        clear temp_ip_pts;
        time_per_step_struct =  struct; % structure for current sample
        stp1_struct = struct; % structure saving stp1 results for diff. NNs
        stp2_struct = struct; % structure saving stp1 results for diff. NNs
	    neighb_struct = struct;
	    for num_val_itr = 1 : size(num_vals_vec,1)
            stp1 = 0;
            stp17 = 0;
            stp18 = 0;
            stp19 = 0;
            stp110 = 0;
            stp2 = 0; 
            num_vals = num_vals_vec(num_val_itr);
            NNRad_vec = linspace(min_rad_val*rect_wall_thick,max_rad_val*rect_wall_thick,num_vals)';
            %% Storage Units
            stp1_pts_res = struct; % Stopping condition 1 
            stp2_pts_res = struct; % Stopping condition 1 & 2 applied
	        loop_ct = 0; % counter to execute stooping condition 2
            %% Iterative Analysis
            % variables for saving data
            % data processing variables
            damaged_points_prev_itr = []; % damaged points refinement variable
            sv_extremes_vec = []; % recording results from STP I thresholding
            ip_point_cloud = org_ip_pc;
            output_points_struct = struct;
            sv_val_vec_struct = struct;
            time_per_step_vec = []; % time vector for current iteration
            thresh_vec = [];
            for iter_itr = 1 : num_iter
                % update the data variables
                % find the output variables structures
                if exist('output_points_struct', 'var')
                    if size(fieldnames(output_points_struct),1) >= 1
                        % calculate field names for the first time
                        if iter_itr == 2
                            fn_names = fieldnames(output_points_struct);
                        end
                        for fn_itr = 1 : size(fn_names,1)
                            output_points_struct(1).(fn_names{fn_itr}) = ...
                                output_points_struct(2).(fn_names{fn_itr});
                        end
                        ip_point_cloud = output_points_struct.PointCloud_updated;
                        damaged_points_prev_itr = output_points_struct.DamagedPoints;
                    end
                    % if not found create an arbritrary structure and logic on
                    % next iteration will take care of rest
                else
                    output_points_struct = struct;
                    continue;
                end
                % stop if eigen value requirements cannot be met
                if stp2 && (size(ip_point_cloud,1) <= 3) 
                    time_per_step_vec(iter_itr,1) = 0;
                    disp("not enough input points");
                    break;
                else
                  % Optimal NN extraction
                  ip_pc_avg_spc = AvgSpace3D(ip_point_cloud);
                  tic; % NN extraction timer begin
                  IPPCkdTreeMdl = KDTreeSearcher(ip_point_cloud);
                  % neighb_struct(num_val_itr).data = OptNNMinEntrPFV4(ip_point_cloud,IPPCkdTreeMdl,NNRad_vec,chunk_size);
                  % neighb_struct_temp = neighb_struct(num_val_itr).data;
                  neighb_struct_temp = OptNNMinEntrPFV4(ip_point_cloud,IPPCkdTreeMdl,NNRad_vec,chunk_size);
                  neighb_struct_data = neighb_struct_temp.data; % extract the radii field for each point
                  clear neighb_struct_temp;
                  % end of time keeping for step 1
                  time_per_step_vec(iter_itr,1) = toc;
                  % save NN rad values for analyzing the input NN rad ranges
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Saving here
                  % opt_nn_rad_vec = [neighb_struct_data(1:end).nn_rad]'; % vectorizing the struct
                  % save(strcat('opt_nn_rad_vec_',ip_data_str,'_',string(iter_itr),'iter_',strrep(string(min_rad_val),'.',''),strrep(string(max_rad_val),'.',''),string(num_vals)),'opt_nn_rad_vec','-v7.3');
        %           clear neighb_struct_data;
                  clear opt_nn_rad_vec;
                end % end of if block checking for stp2
                % apply the combination of analysis for all the undamaged points identified in the previous iteration
                % if ip_point_cloud = [], all points are damaged or error
                % only NN values for the current iteration are considered
                if size(ip_point_cloud,1) > 0
                    % Quantifying data extraction from the input point structure
                    %% Intial Damage Point Labeling
                    temp_struct = struct; % temporary struct for data
                    for itr_strct = 1 : size(neighb_struct_data,2)
                        temp_struct(itr_strct).num_nn = neighb_struct_data(itr_strct).num_nn;
                        temp_struct(itr_strct).eig_val_vec = neighb_struct_data(itr_strct).eig_val_vec;
                    end
                    [damaged_points_cur_unref,~,thresh_value,...
                        time_elapsed_temp1,thresh_vec_temp,sv_val_vec] = ...
                        SVDamPtDetecNNipMaxEntrCuckooV4(ip_point_cloud,...
                        temp_struct,num_thresh,chunk_size);  
                    % if all points have extreme NN regions, assign damaged
                    time_per_step_vec(iter_itr,2) = time_elapsed_temp1;
                    tic;
                    if (sum(sv_val_vec == 4) == size(sv_val_vec,1)) ...
                            || sum(thresh_vec_temp) == 0
                        damaged_points_cur_unref = ip_point_cloud;
                        damaged_points_cur_ref = damaged_points_cur_unref;
                        thresh_vec(iter_itr,:)  = zeros(1,size(thresh_vec,2));
                    else
                         % disp(strcat('Unref. Damaged Points = ',num2str(size(damaged_points_cur_unref,1))));
                        thresh_vec(iter_itr,:) = [min(sv_val_vec),...
                            thresh_vec_temp,max(sv_val_vec(sv_val_vec<0.4))];
                        %% Identified Damage Point Refinement
                        % assign undamaged label if removal of NN points led to high SV 
                        damaged_points_cur_ref = damaged_points_cur_unref;
                        if iter_itr > 1
                            if size(damaged_points_cur_ref,1) > 0
                                indices_size_vec = ones(size(damaged_points_cur_ref,1),1);
                                DmgPtsKDTreeMdl = KDTreeSearcher(damaged_points_prev_itr);
                                % calc. num. of points within the search radius
                                for cur_dmg_pts_itr = 1 : size(damaged_points_cur_ref,1)
                                    indices = rangesearch(DmgPtsKDTreeMdl,damaged_points_cur_ref(cur_dmg_pts_itr,:),NNMultiFactor_prev_iter_pts*ip_pc_avg_spc);
                                    indices_array = indices{1};
                                    indices_size_vec(cur_dmg_pts_itr,1) = size(indices_array,2);
                                end
                                %%%%%%%%%%%%%%%% damaged to undamaged if higher NN region points
                                indices_size_median = median(indices_size_vec);
                                dmg_ref_idx = (indices_size_vec >= indices_size_median);
                                damaged_points_cur_ref = damaged_points_cur_ref(dmg_ref_idx,:);
                            end
                        end
                        % disp(strcat('Ref. Damaged Points = ',num2str(size(damaged_points_cur_ref,1))));
                        % End of Damage Point Labeling
                    end
                    time_per_step_vec(iter_itr,3) = toc; % time taken for refinement step
                    updated_damaged_pts = [damaged_points_prev_itr;damaged_points_cur_ref];
                    % isolate the undamaged points detection from the analysis
                    undamaged_ref_bin = ismember(ip_point_cloud,damaged_points_cur_ref,'rows');
                    updated_undamaged_pts = ip_point_cloud(~undamaged_ref_bin,:);
                    % save the values
                    % update the struct values 
                    output_points_struct(2).thresh_value = thresh_value;
                    output_points_struct(2).thresh_vec = thresh_vec;
                    output_points_struct(2).DamagedPoints = updated_damaged_pts;
                    output_points_struct(2).PointCloud_updated = updated_undamaged_pts;
                    clear thresh_vec_temp;
                    clear undamaged_ref_bin;
                else
                    stp2 = 1;
                    stp1 = 1; % force the first stopping condition as satisfied
                    % iteration when stopping condition reached
                    if iter_itr > 1
                        stp2_pts_res.conv_iter = iter_itr-1;
                        % by iter 2 this struct should have 2 stored results
                        stp2_pts_res.damaged_points = output_points_struct(1).DamagedPoints;
                        stp2_pts_res.undamaged_points = output_points_struct(1).PointCloud_updated;
                        stp2_pts_res.thresh_vec = output_points_struct(1).thresh_vec;
                        stp2_pts_res.time_elapsed = sum(time_elapsed_vec(1: size(time_elapsed_vec,1) - 1));
                        disp(strcat('Algorithm Terminated at Iteration (STP-II): ',num2str(iter_itr)));
                    else
                        disp("!!!!!!!!!!Input Error!!!!!!!!!");
                        stp2_pts_res = struct;
                    end
		            break;
                end
                %% Stopping Condition
                % STP -I
                % Stoppping Condition based on SV value of data
                % highest freq val < has the logic for STP-I
                % save prev. iter. res. for stp-I cond. satisfied for cur. data
                % isolate entropy and SV values for better data handling
                for struct_itr = 1 : size(neighb_struct_data,2)
                    entr_temp = neighb_struct_data(struct_itr).nn_entrp_val;
                    if size(entr_temp,1) == 0
                        entropy_vec_temp(struct_itr) = 0; % arbritrary assignment
                    else
                        entropy_vec_temp(struct_itr) = entr_temp;
                    end
                end
                clear neighb_struct_data;
                % data from current iteration
                sv_val_vec_struct(iter_itr).sv_vec = sv_val_vec;
                sv_val_vec_struct(iter_itr).sv_vec_med = median(sv_val_vec(sv_val_vec < 0.4 & sv_val_vec > 0));
                sv_val_vec_struct(iter_itr).entropy_vec = entropy_vec_temp;
                if  ~stp1
                    cur_sv_val_vec = sv_val_vec_struct(iter_itr).sv_vec;
                    cur_sv_val_vec = cur_sv_val_vec(cur_sv_val_vec < 0.4); % remove arbritrary values
                    % define probablity of SV values in the data
                    sv_extremes_vec(iter_itr,:) = SVFreqAnal(cur_sv_val_vec)';
                    if iter_itr > 1 && iter_itr ~= num_iter
                        % save the result of stp 1 conditions analysis if either passes 
                        if sv_extremes_vec(iter_itr,1) == 0 || ...
                                sv_extremes_vec(iter_itr,2) == 0 || ...
                                sv_extremes_vec(iter_itr,3) == 0 || ...
                                sv_extremes_vec(iter_itr,4) == 0 
                            % Save the current Iteration Results
                            % by iter 2 this struct should have 2 stored results
                            stp1_pts_res.conv_iter = iter_itr;
                            stp1_pts_res.damaged_points = output_points_struct(1).DamagedPoints;
                            stp1_pts_res.undamaged_points = output_points_struct(1).PointCloud_updated;
                            stp1_pts_res.thresh_vec = output_points_struct(1).thresh_vec;
                            stp1_pts_res.time_elapsed = sum(sum(time_per_step_vec(1:iter_itr-1,:)));
                        end 
                        % check for low SV values in the data for STP I
                        zero_idx = find(sv_extremes_vec(iter_itr,:) < 0.0001);
                        for itr_zero = 1 : size(zero_idx,2)
                            switch zero_idx(itr_zero)
                                case 1
                                    if ~stp17
                                        stp17 = 1;
                                        stp107_pts_res = stp1_pts_res;
                                    end
                                case 2
                                    if ~stp18
                                        stp18 = 1;
                                        stp108_pts_res = stp1_pts_res;
                                    end
                                case 3
                                    if ~stp19
                                        stp19 = 1;
                                        stp109_pts_res = stp1_pts_res;
                                    end
                                case 4
                                    if ~stp110
                                        stp110 = 1;
                                        stp110_pts_res = stp1_pts_res;
                                    end
                            end
                        end
%                         save(strcat('stp1_07_',ip_data_str,string(num_vals)),'stp1_pts_res','-v7.3');
%                         save(strcat('stp1_08_',ip_data_str,string(num_vals)),'stp1_pts_res','-v7.3');
%                         save(strcat('stp1_09_',ip_data_str,string(num_vals)),'stp1_pts_res','-v7.3');
%                         save(strcat('stp1_10_',ip_data_str,string(num_vals)),'stp1_pts_res','-v7.3');
                        % if all the conditions are tested, exit STP I
                        if stp17 && stp18 && stp19 && stp110
                          stp1 = 1;
                          disp(strcat('Algorithm Terminated at Iteration(STP-I: ',num2str(iter_itr)));
                        end % end of saving tasks
                    end
                end
                %% STP-II
                % Stopping condition based on ratio of undamaged to damaged points
                if (size(updated_damaged_pts,1)/size(updated_undamaged_pts,1)...
                        >= 1 || iter_itr == num_iter ) && ~stp2 
                    if iter_itr == 1
                        disp(strcat('Algorithm Terminated at Iteration(STP-II): ',num2str(iter_itr)));
                        disp(strcat("!!!!!ERROR!!!!!"))
                        break;
                    end
                    stp2 = 1;
                    % iteration when stopping condition reached
                    % by iter 2 this struct should have 2 stored results
                    stp2_pts_res.conv_iter = iter_itr-1;
                    stp2_pts_res.damaged_points = output_points_struct(1).DamagedPoints;
                    stp2_pts_res.undamaged_points = output_points_struct(1).PointCloud_updated;
                    stp2_pts_res.thresh_vec = output_points_struct(1).thresh_vec;
                    stp2_pts_res.time_elapsed = sum(sum(time_per_step_vec(1:iter_itr-1,:)));
                    disp(strcat('Algorithm Terminated at Iteration(STP-II): ',num2str(iter_itr)));
                    if ~stp1
                        stp1 = 1; % force the first stopping condition as satisfied
                        disp(strcat('Forced Terminated at Iteration(STP-I): ',num2str(iter_itr)));
                        stp1_pts_res.conv_iter = iter_itr;
                        stp1_pts_res.damaged_points = output_points_struct(1).DamagedPoints;
                        stp1_pts_res.undamaged_points = output_points_struct(1).PointCloud_updated;
                        stp1_pts_res.thresh_vec = output_points_struct(1).thresh_vec;
                        stp1_pts_res.time_elapsed = sum(sum(time_per_step_vec(1:iter_itr-1,:)));
                    end
                    break;
                end
                clear ip_point_cloud;
            end % end of iterative analysis
            %% saving data
%             save_str_temp = strcat(rdrive_str, save_str1);
%             save_str = strcat(save_str_temp,file_name,slsh);
%             try % try to save in research drive
%                 if ~isfolder(save_str)
%                     mkdir(save_str)
%                     disp("crating folder", save_str);
%                 end 
%                 disp(strcat("Saved in Research Drive for ",file_name," NN vals - ",string(num_vals_vec(num_val_itr))));
%             catch Err % if not accessible save in local drive
            if ~isfolder(save_str)
                mkdir(save_str)
            end
            disp(strcat("Saved in Local Drive for ",file_name," NN vals - ",string(num_vals_vec(num_val_itr))));
%             end
            save(strcat(save_str,'stp1_result_nnno',string(num_vals_vec(num_val_itr)),"_",strrep(string(min_rad_val),'.',''),"_",strrep(string(max_rad_val),'.','')),'stp1_pts_res','-v7.3')
            save(strcat(save_str,'stp2_result_nnno',string(num_vals_vec(num_val_itr)),"_",strrep(string(min_rad_val),'.',''),"_",strrep(string(max_rad_val),'.','')),'stp2_pts_res','-v7.3')
            save(strcat(save_str,'time_data_nnno',string(num_vals_vec(num_val_itr)),"_",strrep(string(min_rad_val),'.',''),"_",strrep(string(max_rad_val),'.','')),'time_per_step_vec','-v7.3')

            clear stp1_pts_res;
            clear stp2_pts_res;
            clear stp1;
            clear stp17;
            clear stp18;
            clear stp19;
            clear stp110;
            clear stp107_pts_res;
            clear stp108_pts_res;
            clear stp109_pts_res;
            clear stp110_pts_res;
            clear stp2;
            clear time_per_step_vec;
            clear DmgPtsKDTreeMdl;
            clear entr_temp;
            clear IPPCkdTreeMdl;
            clear thresh_vec;
            clear sv_extremes_vec;
            clear iter_itr;
            clear damaged_points_prev_itr;
            clear sv_extremes_vec;
            clear ip_point_cloud;
            clear output_points_struct;
            clear sv_val_vec_struct;
            clear ip_pc_avg_spc;
            clear damaged_points_cur_unref;
            clear damaged_points_cur_ref;
            clear time_elapsed_temp1;
            clear thresh_value;
            clear sv_val_vec;
            clear cur_dmg_pts_itr;
            clear cur_neigh_struct;
            clear cur_sv_val_vec;
            clear dmg_ref_idx;
            clear entropy_vec_temp;
            clear indices;
            clear indices_array;
            clear indices_size_median;
            clear indices_size_vec;
            clear rep_ct_stop;
            clear struct_itr;
            clear time_elapsed_vec;
            clear NNRad_vec;
            clear qt_anal_strct_itr;
            clear updated_damaged_pts;
            clear updated_undamaged_pts;
        end % end of loop for different NN values
	clear neighb_struct;
    end % end of loop for different samples for the same dataset
    clear data_list;
end % end of loop for different dataset
