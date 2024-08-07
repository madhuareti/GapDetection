clc
close all

% local_str = "/home/grads/m/mareti/GapDetect/";
local_str="/home/aisl/GapDetect/";
dir_str = num2str(argName)
save_str_key='cfm_results_0930_dl';
% defining if linux or windows for "/" or "\" usage
slash_key = 'linux';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
gt_path_str = strcat(local_str,'data',slsh,'raw_data',slsh,'panel1',slsh,'damaged_points.mat');
% gt_path_str = strcat(local_str,'data',slsh,'disaster_city',slsh,'damaged_data_complete',slsh,'b134_w1_p1.mat');
try
	load(gt_path_str);
catch err
	disp("Ground Truth Not Found at ");
	gt_path_str
	return;
end
gt_dmg_pts = org_ip_pc;
clear org_ip_pc
device_dir_str = dir_str;
del_keys = [".";".."];
data_strs = CheckFolderSetup(device_dir_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
device_list = dir(fullfile(device_dir_str)) 
%% Quantitative Analysis
res_ct = 1; % counter for number of unique analysis
samp_param_data = []; % save the sample name and param set identifiers
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories in this directory'));
% return; % debugging for linux loop
while min(size(data_strs_loop)) >= 1
    % find all results from single iteration
    cur_path = data_strs_loop{1};
    param_key_temp1 = split(cur_path,device_dir_str);
    param_key_temp2 = split(param_key_temp1{2},'.mat');
    if size(param_key_temp2,1) > 1
        param_key_temp3 = split(param_key_temp2{1},'sample_')
        if size(param_key_temp3,1) > 1
            param_key_temp4 = split(param_key_temp3{2},slsh);
            param_key1 = param_key_temp4{1} % name of the sample
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
    while size(sample_list_loop,1) > 0
        param_key_temp5 = split(sample_list_loop{1},'nnno');
        param_key_temp6 = split(param_key_temp5{2},'.mat');
        param_key2 = param_key_temp6{1} % param set used
        samp_param_data{res_ct,1} = strcat("sample_",param_key1);
        samp_param_data{res_ct,2} = param_key2;
        cur_list_bin = cellfun(@(x) MatchKeys(x, param_key2), sample_list_loop);
        cur_param_list = sample_list_loop(find(cur_list_bin)); %#ok<FNDSB>
        sample_list_loop = sample_list_loop(find(~cur_list_bin)); %#ok<FNDSB>
        % load results from current parameter set
        %% Quantitative Analysis
        for itr_data = 1 : size(cur_param_list)
            try
                load(cur_param_list{itr_data});
            catch Err
		disp("Error Loading ");
		cur_param_list(itr_data)
                continue
            end
        end
        if exist("stp1_pts_res",'var') && exist("stp2_pts_res",'var')
    % %         plot_stp1stp2;
            [AlgoRecall_arr_ref(res_ct,1),AlgoPrecision_arr_ref(res_ct,1),...
                AlgoF1Score_arr_ref(res_ct,1),AlgoAccuracy_arr_ref(res_ct,1)...
                ,AlgoMCC_arr_ref(res_ct,1),TP_num_ref(res_ct,1),...
                FP_num_ref(res_ct,1),TN_num_ref(res_ct,1),FN_num_ref(res_ct,1)] ...
                = QuantitativeAnalysisCFMV3(stp1_pts_res.damaged_points,...
                    stp1_pts_res.undamaged_points,gt_dmg_pts);
            [AlgoRecall_arr_ref(res_ct,2),AlgoPrecision_arr_ref(res_ct,2),...
                AlgoF1Score_arr_ref(res_ct,2),AlgoAccuracy_arr_ref(res_ct,2)...
                ,AlgoMCC_arr_ref(res_ct,2),TP_num_ref(res_ct,2),...
                FP_num_ref(res_ct,2),TN_num_ref(res_ct,2),FN_num_ref(res_ct,2)] ...
                = QuantitativeAnalysisCFMV3(stp2_pts_res.damaged_points,...
                    stp2_pts_res.undamaged_points,gt_dmg_pts);
            time_vec(res_ct,1) = stp1_pts_res.time_elapsed;
            time_vec(res_ct,2) = stp2_pts_res.time_elapsed;
            clear stp1_pts_res
            clear stp2_pts_res
            clear time_per_step_vec
            clear output_points_struct
            close all
            res_ct = res_ct + 1;
        end
    end
end
save_str = strcat(device_dir_str,save_str_key);
if isfolder(save_str) % most cases until the path input is wronng this folder is present
    mkdir(save_str);
end
if exist('AlgoMCC_arr_ref','var')
    if size(AlgoMCC_arr_ref,1) < size(samp_param_data,1)
    	samp_param_data(size(AlgoMCC_arr_ref,1)+1 : end,:) = [];
    end
        save(save_str,'AlgoRecall_arr_ref','AlgoPrecision_arr_ref','AlgoF1Score_arr_ref',...
                'AlgoAccuracy_arr_ref','AlgoMCC_arr_ref','TP_num_ref','FP_num_ref',...
                'TN_num_ref','FN_num_ref','time_vec','samp_param_data','-v7.3')

end
