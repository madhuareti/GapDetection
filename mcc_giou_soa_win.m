clc
close all
clear
% local_str = "/home/aisl/GapDetect/";
local_str="C:\Users\mareti\Desktop\local\";
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
panel_str = "";
% dir_str = strcat("results",slsh,"oriented_xyz_ws_zb",slsh);
% save_str_temp = strcat("results",slsh,"quant_results",slsh,"pa_10_13",slsh);
% dir_str = strcat("results",slsh,"OITRA",slsh,"oriented_xyz",slsh);
% save_str_temp = strcat("results",slsh,"quant_results",slsh,"oitra_10_13",slsh);
dir_str = strcat("results",slsh,"GITRA",slsh,"11_06",slsh);
save_str_temp = strcat("results",slsh,"quant_results",slsh,"gitra_11_06",slsh);
img_save_str1 = strcat("giou_images",slsh);
gt_clust_dir_str = strcat(local_str,'data',slsh,'disaster_city',slsh,'damaged_points_clustered_all',slsh);
% projection parameters - defined based on data orientation
% panel_str = ["b130_w2_p2_hole" "b133_w2_p4_hole" "b134_w3_p2" "b133_w2_p3" "b134_w3_p1"... 
%     "b133_w1_p1" "b130_w2_p1" "b134_w1_p1" "b130_w1_p3" ...
%     "b133_w2_p5" "b134_w2_p3" "b133_w2_p2" "b134_w2_p1" "b130_w3_p1"];
% panel_normal = [1 0 0; 1 0 0; 1 0 0; 1 0 0; 1 0 0; 0 1 0; 0 1 0; ... 
%     1 0 0; 1 0 0; 1 0 0; 0 1 0; 1 0 0; 0 1 0; 0 1 0];  
 % define if the planar points are in - or + direction 
% panel_proj_mean_key = ["min" "max" "min" "max" "min" "min" "min" "max"...
%      "max" "max" "min" "max" "min" "max"];
panel_str = ["b130_w1_p3" "b130_w2_p1" "b130_w2_p2_hole" "b130_w3_p1" ...
    "b133_w1_p1" "b133_w2_p2" "b133_w2_p3" "b133_w2_p4_hole" "b133_w2_p5"...
    "b134_w1_p1" "b134_w2_p1" "b134_w2_p3" "b134_w3_p1" "b134_w3_p2"];
panel_normal = [1 0 0; 1 0 0; 1 0 0; 0 1 0;0 1 0; 1 0 0; 1 0 0; 1 0 0;...
    1 0 0; 1 0 0; 0 1 0;0 1 0;1 0 0;1 0 0];
panel_proj_mean_key = ["max" "min" "min" "max" "min" "max" "max" "max"...
    "max" "max" "min" "min" "min" "min"];
% best performers for gitra (manual observation)
gitra_str_sample = ["sample_10_05" "sample_10_01" "sample_5_01" "sample_1_01" "sample_3_01" "sample_10_01" "sample_5_01" "sample_4_01" "sample_10_01" "sample_8_01" "sample_2_01" "sample_10_01" "sample_6_01" " "];
device_dir_str = strcat(local_str,dir_str);
del_keys = [".";".."];
data_strs = CheckFolderSetup(device_dir_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
%% parameters to choose the analysis style
oitra_bin = false;
giou_bin = true;
gitra_init_bin = false;
gitra_bin = true;
%% Quantitative Analysis
samp_param_data = []; % save the sample name and param set identifiers
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
% remove all the undesired files (files with cfm tag)
% return; % debugging for linux loop
% cut_loop = 0; % loop cutter for specific case of 200 iterations
%% for clearing old result files 
if ~gitra_init_bin % ignore the case when files are being compiled
    cur_sample_bin = cellfun(@(x) MatchKeys(x, '_results'), data_strs_loop);
    data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
    disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories to be deleted in this directory'));
    if min(size(data_strs_loop)) > 0
        for itr = 1 : max(size(data_strs_loop))
            delete(data_strs_loop{itr});
        end
    end
end
%% for intial analysis - combining all data into results two files per folder
device_list = dir(fullfile(device_dir_str));
samp_param_data = []; % save the sample name and param set identifiers
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
% analyze only op struct results
keep_key = "op_struct_";
cur_sample_bin = cellfun(@(x) MatchKeys(x, keep_key), data_strs_loop);
data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories in this directory'));
data_quant_ct = 0; % counter for all the results that are analyzed
panel_ct = 0; % counter for number of panels
giou_struct = struct;
quant_struct = struct; %
best_quant_struct = struct; % filtering gitra
while min(size(data_strs_loop)) >= 1
    % find all results from single iteration
    cur_path = data_strs_loop{1};
    param_key_temp1 = split(cur_path,device_dir_str);
    param_key_temp2 = split(param_key_temp1{2},'.mat');
    if size(param_key_temp2,1) > 1
        param_key_temp3 = split(param_key_temp2{1},slsh);
        if size(param_key_temp3,1) > 1
            param_key1 = param_key_temp3{1}; % name of the panel
        else
            data_strs_loop(1) =[];
            continue
        end
    else
        data_strs_loop(1) =[];
        continue
    end
    % find all the results from the current sample
    cur_sample_bin = cellfun(@(x) MatchKeys(x, param_key1), data_strs_loop);
    cur_sample_list = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
    data_strs_loop = data_strs_loop(find(~cur_sample_bin)); %#ok<FNDSB> 
    % find all the results for the current sample and current parameters
    sample_list_loop = cur_sample_list;
    while min(size(sample_list_loop)) > 0
        % load the ground truth damaged points for the panel
        param_key1 = split(param_key1,"_sample");
        param_key1 = param_key1{1};
        gt_path_str = strcat(gt_clust_dir_str,param_key1,'.mat');
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
        % only look at best sample for GITRA GIoU calculation
        if gitra_bin
            sample_bin = ismember(panel_str,param_key1);
            sample_idx = find(sample_bin);
            param_key3 = gitra_str_sample(sample_idx);
            if isempty(param_key3)
                continue;
                sample_list_loop = [];
            end
            cur_list_bin_param = cellfun(@(x) MatchKeys(x, param_key3), sample_list_loop);
            upd_rm_idxs = find(cur_list_bin_param); % extract indexes of relevant files
            cur_param_list = sample_list_loop(upd_rm_idxs); 
            sample_list_loop = [];
            sample_list_loop{1} = cur_param_list;
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
                cur_path = string(cur_param_list{itr_data});
                load(cur_path);
            catch
		        disp("Error Loading ");
		        cur_param_list(itr_data)
                continue;
            end
            % extract data from results loaded 
            cur_data_struct = save_file1.data;
            cur_cfm_struct = save_file1.CFM;
            cur_best_params = save_file1.params; % best param values
            damaged_points_res = cur_data_struct.DamagedPoints;
            % Projection Parameters
            proj_nrml_bin = ismember(panel_str,param_key1);
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
            if size(damaged_points_res,1) < 3
                continue
            end
            data_quant_ct = data_quant_ct + 1;
            if giou_bin
                [giou_val_vec,mean_giou_val,tot_time] = ...
                    GeometricAnalysis(org_gt_damaged_point_struct,...
                    damaged_points_res,proj_normal,proj_mean);
                giou_struct(data_quant_ct).panel_id = param_key1;
                giou_struct(data_quant_ct).sample_id = param_key3;
                giou_struct(data_quant_ct).param_set = cur_best_params;
                giou_struct(data_quant_ct).giou_vec = giou_val_vec;
                giou_struct(data_quant_ct).mgiou = mean_giou_val;
                giou_struct(data_quant_ct).time = tot_time;
            end
            %% Quantitative Analysis - MCC
            AlgoRecall_vec(data_quant_ct,1) = cur_cfm_struct.Recall;
            AlgoPrecision_vec(data_quant_ct,1) = cur_cfm_struct.Precision;
            AlgoF1Score_vec(data_quant_ct,1) = cur_cfm_struct.F1;
            AlgoAccuracy_vec(data_quant_ct,1) = cur_cfm_struct.Accuracy;
            AlgoMCC_vec(data_quant_ct,1) = cur_cfm_struct.MCC;
            TP_num_vec(data_quant_ct,1) = cur_cfm_struct.TPnum;
            FP_num_vec(data_quant_ct,1) = cur_cfm_struct.FPnum;
            TN_num_vec(data_quant_ct,1) = cur_cfm_struct.TNnum;
            FN_num_vec(data_quant_ct,1) = cur_cfm_struct.FNnum;
            samp_param_data{data_quant_ct,1} = param_key1;
            samp_param_data{data_quant_ct,2} = param_key2;
            samp_param_data{data_quant_ct,3} = param_key3;
            % save 
            if max(size(param_key3)) > 0
                param_key3_temp = split(param_key3,"sample_");
                save_str_key = strcat(param_key1,"_",param_key3_temp{2});
                save_dir_str = strcat(local_str,save_str_temp,param_key1,slsh,save_str_key);
                if gitra_init_bin
                    img_save_dir = strcat(local_str,save_str_temp,img_save_str1,param_key1,slsh);
                end
                if gitra_bin
                    img_save_dir = strcat(local_str,save_str_temp,img_save_str1);
                    save_dir_str = strcat(local_str,save_str_temp);
                end
            else
                save_str_key = strcat(param_key1);
                save_dir_str = strcat(local_str,save_str_temp);
                img_save_dir = strcat(local_str,save_str_temp,img_save_str1);
            end
            save_str_cfm_giou = strcat(save_dir_str,slsh,save_str_key,'_cfm_mgiou_results.mat');
            save_str_cfm = strcat(save_dir_str,slsh,save_str_key,'_cfm_results.mat');
            if ~isfolder(save_dir_str) % most cases until the path input is wronng this folder is present
                mkdir(save_dir_str);
            end
            if giou_bin
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
                img_save_str  = strcat(img_save_dir,save_str_key,'.png');
                saveas(gcf,img_save_str);
                close all
            end
            if exist('AlgoMCC_vec','var')
                if size(AlgoMCC_vec,1) < size(samp_param_data,1)
    	            samp_param_data(size(AlgoMCC_vec,1)+1 : end,:) = [];
                end
                if oitra_bin || gitra_bin
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
            end
        end % end of for loop trying to load the result
    end % end of while loop for current panel
    % use this only for intial gitra data retrieval
    if gitra_init_bin
        panel_ct = panel_ct + 1;
        % save all data
        quant_struct(panel_ct).panel_id = samp_param_data(:,1);
        quant_struct(panel_ct).sample_id = samp_param_data(:,3);
        quant_struct(panel_ct).param_set = samp_param_data(:,2);
        quant_struct(panel_ct).AlgoRecall_vec = AlgoRecall_vec;
        quant_struct(panel_ct).AlgoPrecision_vec = AlgoPrecision_vec;
        quant_struct(panel_ct).AlgoF1Score_vec = AlgoF1Score_vec;
        quant_struct(panel_ct).AlgoAccuracy_vec = AlgoAccuracy_vec;
        quant_struct(panel_ct).AlgoMCC_vec = AlgoMCC_vec;
        quant_struct(panel_ct).TP_num_vec = TP_num_vec;
        quant_struct(panel_ct).FP_num_vec = FP_num_vec;
        quant_struct(panel_ct).TN_num_vec = TN_num_vec;
        quant_struct(panel_ct).FN_num_vec = FN_num_vec;
        % best quant structure
        [~,best_idx] = max(AlgoAccuracy_vec);
        best_quant_struct(panel_ct).panel_id = samp_param_data(best_idx,1);
        best_quant_struct(panel_ct).sample_id = samp_param_data(best_idx,3);
        best_quant_struct(panel_ct).param_set = samp_param_data(best_idx,2);
        best_quant_struct(panel_ct).AlgoRecall_vec = AlgoRecall_vec(best_idx);
        best_quant_struct(panel_ct).AlgoPrecision_vec = AlgoPrecision_vec(best_idx);
        best_quant_struct(panel_ct).AlgoF1Score_vec = AlgoF1Score_vec(best_idx);
        best_quant_struct(panel_ct).AlgoAccuracy_vec = AlgoAccuracy_vec(best_idx);
        best_quant_struct(panel_ct).AlgoMCC_vec = AlgoMCC_vec(best_idx);
        best_quant_struct(panel_ct).TP_num_vec = TP_num_vec(best_idx);
        best_quant_struct(panel_ct).FP_num_vec = FP_num_vec(best_idx);
        best_quant_struct(panel_ct).TN_num_vec = TN_num_vec(best_idx);
        best_quant_struct(panel_ct).FN_num_vec = FN_num_vec(best_idx);
        best_quant_struct(panel_ct).AvgMCC = mean(AlgoMCC_vec);
        best_quant_struct(panel_ct).AvgACC = mean(AlgoAccuracy_vec);
        AlgoRecall_vec = [];
        AlgoPrecision_vec = [];
        AlgoF1Score_vec = [];
        AlgoAccuracy_vec = [];
        AlgoMCC_vec = [];
        TP_num_vec = [];
        FP_num_vec = [];
        TN_num_vec = [];
        FN_num_vec = [];
        samp_param_data = [];
    end
end % end of while loop for all the panels in the directory
if gitra_init_bin
    save_str_cfm_tot = strcat(local_str,save_str_temp,"complete_gitra_cfm.mat");
    save(save_str_cfm_tot,'quant_struct','-v7.3');
    save_str_cfm_best = strcat(local_str,save_str_temp,"best_gitra_cfm.mat");
    save(save_str_cfm_best,'best_quant_struct','-v7.3');
end
