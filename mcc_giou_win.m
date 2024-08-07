clc
close all
clear
% local_str = "/home/aisl/GapDetect/";
% local_str="C:\Users\mareti\Desktop\local\";
local_str = "C:\Users\mareti\Downloads\";
gt_local_str = "C:\Users\mareti\Desktop\local\";
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
panel_str_key = "";
% dir_str = strcat("results",slsh,"oriented_xyz_zb_1108",slsh);
dir_str = strcat("Newfolder",slsh);
save_str_temp = strcat("results",slsh,"quant_results",slsh,"pa_11_08",slsh);
% dir_str = strcat("results",slsh,"OITRA",slsh,"oriented_xyz",slsh);
% save_str_temp = strcat("results",slsh,"quant_results",slsh,"oitra_10_13",slsh);
% dir_str = strcat("results",slsh,"GITRA",slsh,"oriented_xyz_1014",slsh);
% save_str_temp = strcat("results",slsh,"quant_results",slsh,"gitra_10_14",slsh);
img_save_str1 = strcat("giou_images",slsh);
gt_clust_dir_str = strcat(gt_local_str,'data',slsh,'disaster_city',slsh,'damaged_points_clustered_all',slsh);
% projection parameters - defined based on data orientation
% panel_str = ["b130_w2_p2_hole" "b133_w2_p4_hole" "b134_w3_p2" "b133_w2_p3" "b134_w3_p1"... 
%     "b133_w1_p1" "b130_w2_p1" "b134_w1_p1" "b130_w1_p3" ...
%     "b133_w2_p5" "b134_w2_p3" "b133_w2_p2" "b134_w2_p1" "b130_w3_p1"];
% panel_normal = [1 0 0; 1 0 0; 1 0 0; 1 0 0; 1 0 0; 0 1 0; 0 1 0; ... 
%     1 0 0; 1 0 0; 1 0 0; 0 1 0; 1 0 0; 0 1 0; 0 1 0];  
 % define if the planar points are in - or + direction 
% panel_proj_mean_key = ["min" "max" "min" "max" "min" "min" "min" "max"...
%      "max" "max" "min" "max" "min" "max"];
% best performers for gitra (manual observation)
% gitra_str_panel = ["b130_w2_p2_hole " "b133_w2_p4_hole " "b133_w2_p3 " "b134_w3_p2 " "b134_w3_p1 " "b133_w1_p1 " "b133_w2_p5 " "b134_w1_p1 " "b130_w2_p1 " "b130_w1_p3 " "b134_w2_p3 " "b133_w2_p2 " "b134_w2_p1 " "b130_w3_p1"];
% gitra_str_sample = ["sample_6_05" "sample_8_07 " "sample_10_05 " "sample_9_03 " "sample_10_01 " "sample_10_05 " "sample_2_01 " "sample_7_01 " "sample_10_07 " "sample_10_01 " "sample_2_01 " "sample_6_01 " "sample_9_05 " "sample_2_01"];
panel_str = ["b130_w1_p3" "b130_w2_p1" "b130_w2_p2_hole" "b130_w3_p1" ...
    "b133_w1_p1" "b133_w2_p2" "b133_w2_p3" "b133_w2_p4_hole" "b133_w2_p5"...
    "b134_w1_p1" "b134_w2_p1" "b134_w2_p3" "b134_w3_p1" "b134_w3_p2"];
panel_normal = [1 0 0; 1 0 0; 1 0 0; 0 1 0;0 1 0; 1 0 0; 1 0 0; 1 0 0;...
    1 0 0; 1 0 0; 0 1 0;0 1 0;1 0 0;1 0 0];
panel_proj_mean_key = ["max" "min" "min" "max" "min" "max" "max" "max"...
    "max" "max" "min" "min" "min" "min"];
device_dir_str = strcat(local_str,dir_str);
del_keys = [".";".."];
data_strs = CheckFolderSetup(device_dir_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
%% Quantitative Analysis
samp_param_data = []; % save the sample name and param set identifiers
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
% remove all the undesired files (files with cfm tag)
% return; % debugging for linux loop
% cut_loop = 0; % loop cutter for specific case of 200 iterations
%% for clearing old result files 
cur_sample_bin = cellfun(@(x) MatchKeys(x, 'giou'), data_strs_loop);
data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories to be deleted in this directory'));
if min(size(data_strs_loop)) > 0
    for itr = 1 : max(size(data_strs_loop))
        delete(data_strs_loop{itr});
    end
end
%% for intial analysis - combining all data into results two files per folder
device_list = dir(fullfile(device_dir_str));
samp_param_data = []; % save the sample name and param set identifiers
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
if ~isempty(panel_str_key)
    cur_sample_bin = cellfun(@(x) MatchKeys(x, panel_str_key), data_strs_loop);
    data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
end
% analyze only op struct results
keep_key = "stp2_result_nnno";
cur_sample_bin = cellfun(@(x) MatchKeys(x, keep_key), data_strs_loop);
data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories in this directory'));
data_quant_ct = 0; % counter for all the results that are analyzed
giou_struct = struct;
while min(size(data_strs_loop)) >= 1
    % find all results from single iteration
    cur_path = data_strs_loop{1};
    param_key_temp1 = split(cur_path,device_dir_str);
    param_key_temp2 = split(param_key_temp1{2},'.mat');
    if size(param_key_temp2,1) > 1
        param_key_temp3 = split(param_key_temp2{1},slsh);
        while isempty(param_key_temp3{1})
            param_key_temp3(1) = [];
        end
        if size(param_key_temp3,1) > 1
            gt_param_key1 = param_key_temp3{1}; % name of the panel
        else
            data_strs_loop(1) =[];
            continue
        end
    else
        data_strs_loop(1) =[];
        continue
    end
    % find all the results from the current sample
    cur_sample_bin = cellfun(@(x) MatchKeys(x, gt_param_key1), data_strs_loop);
    cur_sample_list = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
    data_strs_loop = data_strs_loop(find(~cur_sample_bin)); %#ok<FNDSB> 
    % find all the results for the current sample and current parameters
    sample_list_loop = cur_sample_list;
    while min(size(sample_list_loop)) > 0
        % load the ground truth damaged points for the panel
        param_key1 = gt_param_key1;
        gt_param_key1_temp = split(gt_param_key1,"_sample");
        gt_param_key1_temp2 = split(gt_param_key1_temp{1},"_");
        if strcmp(gt_param_key1_temp2(end),"hole")
            gt_param_key1 = param_key1;
        else
            gt_param_key1 = strjoin(gt_param_key1_temp2(1:3),"_");
        end
        gt_path_str = strcat(gt_clust_dir_str,gt_param_key1,'.mat');
        try
            load(gt_path_str);
        catch
            disp("Error Loading GT ");
            gt_path_str
            sample_list_loop = []; % if GT is not found skip all the results for that panel
            continue;
        end
        gt_damaged_pts = [];
        for itr_gt = 1 : size(org_gt_damaged_point_struct,2)
            gt_damaged_pts = [gt_damaged_pts;org_gt_damaged_point_struct(itr_gt).data];
        end
        param_key_temp5 = split(sample_list_loop{1},strcat(dir_str,param_key1)); % 
        param_key_temp6 = split(param_key_temp5{2},slsh);
        param_key_temp7 = split(param_key_temp6{end},'.mat');
        param_key_temp8 = split(param_key_temp7{1},keep_key);
        if size(param_key_temp8,1) == 1 % skip the loop if crrent file is not relevanr
            sample_list_loop(1) = [];
            continue
        end
        param_key2 = param_key_temp8{2}; % param set used
        if isfolder(strcat(device_dir_str,param_key1,slsh,param_key_temp6{2}))
            param_key3 = param_key_temp6{2}; % sample number
            % extract for the current sample
            cur_list_bin_samp = cellfun(@(x) MatchKeys(x, param_key3), sample_list_loop);
            rm_idxs = find(cur_list_bin_samp);  % extract indexes of relevant files
            cur_param_list = sample_list_loop(rm_idxs);  
        else
            param_key3 = [];
            rm_idxs = false(size(sample_list_loop,1),1);
            cur_param_list = sample_list_loop;  
        end
        % extract for the current parameters
        cur_list_bin_param = cellfun(@(x) MatchKeys(x, param_key2), cur_param_list);
        upd_rm_idxs = find(cur_list_bin_param); % extract indexes of relevant files
        cur_param_list = sample_list_loop(upd_rm_idxs); 
        sample_list_loop(upd_rm_idxs) = [];
        %% Quantitative Analysis - mGIoU
        % load the result
        for itr_data = 1 : size(cur_param_list)
            try
                load(cur_param_list{itr_data});
            catch
		        disp("Error Loading ");
		        cur_param_list(itr_data)
                continue;
            end
            damaged_points_res = stp2_pts_res.damaged_points;
            % Projection Parameters
            proj_nrml_bin = ismember(panel_str,gt_param_key1);
            proj_nrml_idx = find(proj_nrml_bin);
            proj_normal = panel_normal(proj_nrml_idx,:);
            [~,idx] = max(proj_normal); % find the orientation index
            proj_mean = zeros(1,3);
            % ensure the projection mean is on the planar region
            switch panel_proj_mean_key(proj_nrml_idx)
                case 'max'
                     proj_mean(idx) = max(damaged_points_res(:,idx));
                case 'min'
                     proj_mean(idx) = min(damaged_points_res(:,idx));
            end
            [giou_val_vec,mean_giou_val,tot_time] = ...
                GeometricAnalysis(org_gt_damaged_point_struct,...
                damaged_points_res,proj_normal,proj_mean);
            data_quant_ct = data_quant_ct + 1;
            giou_struct(data_quant_ct).panel_id = param_key1;
            giou_struct(data_quant_ct).sample_id = param_key3;
            giou_struct(data_quant_ct).nn_param_set = param_key2;
            giou_struct(data_quant_ct).giou_vec = giou_val_vec;
            giou_struct(data_quant_ct).mgiou = mean_giou_val;
            giou_struct(data_quant_ct).time = tot_time;
            %% Quantitative Analysis - MCC
            if exist("stp2_pts_res",'var')
                [AlgoRecall_vec(data_quant_ct,1),AlgoPrecision_vec(data_quant_ct,1),...
                    AlgoF1Score_vec(data_quant_ct,1),AlgoAccuracy_vec(data_quant_ct,1)...
                    ,AlgoMCC_vec(data_quant_ct,1),TP_num_vec(data_quant_ct,1),...
                    FP_num_vec(data_quant_ct,1),TN_num_vec(data_quant_ct,1),FN_num_vec(data_quant_ct,1)] ...
                    = QuantitativeAnalysisCFMV3(stp2_pts_res.damaged_points,...
                        stp2_pts_res.undamaged_points,gt_damaged_pts);
                time_vec(data_quant_ct,1) = stp2_pts_res.time_elapsed;
                clear stp2_pts_res
                clear time_per_step_vec
                clear output_points_struct
            end
            samp_param_data{data_quant_ct,1} = param_key1;
            samp_param_data{data_quant_ct,2} = param_key2;
            samp_param_data{data_quant_ct,3} = param_key3;
           % save 
            if max(size(param_key3)) > 0
                param_key3_temp = split(param_key3,"sample_");
                save_str_key = strcat(param_key1,"_",param_key3_temp{2});
                save_dir_str = strcat(local_str,save_str_temp,param_key1,slsh,save_str_key);
                img_save_dir = strcat(local_str,save_str_temp,img_save_str1,param_key1,slsh);
            else
                save_str_key = strcat(param_key1);
                save_dir_str = strcat(local_str,save_str_temp);
                img_save_dir = strcat(local_str,save_str_temp,img_save_str1);
            end
            save_str_cfm_giou = strcat(save_dir_str,slsh,save_str_key,'_cfm_mgiou_results.mat');
            if ~isfolder(save_dir_str) % most cases until the path input is wronng this folder is present
                mkdir(save_dir_str);
            end
            % save the giou plots
            if ~isfolder(img_save_dir) % most cases until the path input is wronng this folder is present
                mkdir(img_save_dir);
            end
            % edit the plots
            if max(size(param_key3)) > 0
                title(string(param_key1),'Interpreter','none');
                subtitle(string(param_key3),'Interpreter','none');
            else
                title(string(param_key1), 'Interpreter','none');
            end
            if sum(proj_normal == [0 1 0]) == 3
                xlabel('X(cm)')
                ylabel('Z(cm)')
            else
                if sum(proj_normal == [1 0 0]) == 3
                    xlabel('Y(cm)')
                    ylabel('Z(cm)')
                end
            end
            img_save_str  = strcat(img_save_dir,save_str_key,'.tiff');
            exportgraphics(gcf,img_save_str,'Resolution',300);
            close all
            if exist('AlgoMCC_vec','var')
                if size(AlgoMCC_vec,1) < size(samp_param_data,1)
    	            samp_param_data(size(AlgoMCC_vec,1)+1 : end,:) = [];
                end
                save(save_str_cfm_giou,'AlgoRecall_vec','AlgoPrecision_vec','AlgoF1Score_vec',...
                        'AlgoAccuracy_vec','AlgoMCC_vec','TP_num_vec','FP_num_vec',...
                        'TN_num_vec','FN_num_vec',...
                        'samp_param_data','giou_struct','-v7.3');
                data_quant_ct = 0;
                giou_struct = struct;
                AlgoRecall_vec = [];
                AlgoPrecision_vec = [];
                AlgoF1Score_vec = [];
                AlgoAccuracy_vec = [];
                AlgoMCC_vec = [];
                TP_num_vec = [];
                FP_num_vec = [];
                TN_num_vec = [];
                FN_num_vec = [];
                time_vec = [];
                samp_param_data = [];
            end
        end % end of for loop trying to load the result
    end % end of while loop for current panel
end % end of while loop for all the panels in the directory

