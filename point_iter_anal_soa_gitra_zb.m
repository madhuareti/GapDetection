clear;
clc;
close all;
if ~isempty(gcp('nocreate'))
  delete(gcp('nocreate'));
end
try
  parpool(feature('numCores'));
catch Err
  Err
  a = Err.cause;
  a{1}
  disp('parpool intialization failed, quitting matlab');
  quit; % quitting matlab if fails
end
%% Parameters
num_iter = 10; % number of iterations to be performed
chunk_size = 2000; % chunk size for data division for parallel processing
% defining if linux or windows for "/" or "\" usage
slash_key = 'linux';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
local_str = "/home/aisl/GapDetect/";
dir_str = strcat("data",slsh,"disaster_city",slsh);
data_str1 = strcat("sample_data_complete_1007",slsh);
gt_str1 = "damaged_points_complete";
sample_tag = [];
% neighb_struct = struct;
% OutputPoints_struct = struct; % pre refinement all results
OutputPoints_struct_opt = struct; % pre-refinement best result
OutputPoints_ref_struct_opt = struct; % post-refinement best result
mcc_acc_struct_full = struct; % save mcc for all samples of current data
time_per_step_struct = struct;
% step -I -- intial damage labeling
% step -II -- iterative refinement (eaxh iteartion seperate time recorded)
ip_str = strcat(local_str,dir_str,data_str1,sample_tag);
% extract all the samples in a directory
file_type = ".mat"; % only extract values with this extension
del_keys = [".";".."]; % delete files with this extension
keys_struct = struct; % combine both keys for input
keys_struct(1).value = del_keys;
bin_struct = struct; % combine both operation values for input
bin_struct(1).value = "delete";
dir_strs = FileExtractDirAll(ip_str,bin_struct,keys_struct,file_type,slsh);
%dir_strs = dir_strs(dir_strs_bin)
if size(dir_strs,1) < 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
for ip_sample_itr = 1 : size(dir_strs,1)
    cur_ip_dir_str = strcat(dir_strs(ip_sample_itr).folder,slsh,dir_strs(ip_sample_itr).name);
    if isfolder(cur_ip_dir_str) % entire directory processing
        data_list = dir(fullfile(cur_ip_dir_str,'*.mat'));
    else % process a single ile and not an entire directory
        cur_ip_dir_str = dir_strs(ip_sample_itr).folder;
        data_list = dir_strs;
    end
    size(data_list,1)
    % iterate over all the samples within a data directory
    for ip_data_dir_itr = 1 : size(data_list,1)
        %% load data
       panel_name_temp = split(data_list(ip_data_dir_itr).folder,slsh);
        panel_name = string(panel_name_temp(end));
        %% Paramater Definitaion based on results from OITRA
    switch panel_name
        case 'b130_w2_p2_hole'
            nn_mult_vec = 7;
            ThrshMulFacArr = 0;
            nn_mult_vec_ref = 19;
            ThrshMulFacArr_ref = -2.2; 
        case 'b133_w2_p4_hole'
            nn_mult_vec = 7;
            ThrshMulFacArr = -0.1;
            nn_mult_vec_ref = 19;
            ThrshMulFacArr_ref = -1.6;
        case 'b133_w2_p3'
            nn_mult_vec = 16;
            ThrshMulFacArr = 1.3;
            nn_mult_vec_ref = 4;
            ThrshMulFacArr_ref = -1.6;
        case 'b134_w3_p1'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.1;
            nn_mult_vec_ref = 4;
            ThrshMulFacArr_ref = -1.6;
        case 'b133_w1_p1'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.4;
            nn_mult_vec_ref = 16;
            ThrshMulFacArr_ref = -1.3;
        case 'b130_w2_p1'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.1;
            nn_mult_vec_ref = 4;
            ThrshMulFacArr_ref = -1.9;
        case 'b134_w1_p1'
            nn_mult_vec = 4;
            ThrshMulFacArr = 0;
            nn_mult_vec_ref = 10;
            ThrshMulFacArr_ref = 1.3;
        case 'b130_w1_p3'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.1;
            nn_mult_vec_ref = 7;
            ThrshMulFacArr_ref = -1.9;
        case 'b133_w2_p5'
            nn_mult_vec = 4;
            ThrshMulFacArr = 0.1;
            nn_mult_vec_ref = 10;
            ThrshMulFacArr_ref = -1;
        case 'b134_w2_p3'
            nn_mult_vec = 4;
            ThrshMulFacArr = 0;
            nn_mult_vec_ref = 16;
            ThrshMulFacArr_ref = -1.6;
        case 'b133_w2_p2'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.4;
            nn_mult_vec_ref = 4;
            ThrshMulFacArr_ref = -1.3;
        case 'b134_w2_p1'
            nn_mult_vec = 7;
            ThrshMulFacArr = -0.7;
            nn_mult_vec_ref = 4;
            ThrshMulFacArr_ref = -1;
        case 'b130_w3_p1'
            nn_mult_vec = 4;
            ThrshMulFacArr = -0.1;
            nn_mult_vec_ref = 10;
            ThrshMulFacArr_ref = -1.3;
    end
    nn_mult_vec_str = strrep(string(min(nn_mult_vec)),'.','');
	thrsh_mult_vec_str = strrep(string(min(ThrshMulFacArr)),'.','');
    nn_mult_vec_ref_str = strrep(string(min(nn_mult_vec_ref)),'.','');
    thrsh_mult_vec_ref_str = strrep(string(min(ThrshMulFacArr_ref)),'.','');
	file_name_temp = split(data_list(ip_data_dir_itr).name,'.');
        file_name = file_name_temp{1};
        ip_data_str_pc = strcat(cur_ip_dir_str,slsh,file_name,".mat")
        load(ip_data_str_pc);
        ip_point_cloud = cartographic_result;
        % extract the org file name
	gt_dir_str_temp = split(ip_data_str_pc,file_name);
	gt_path_str_temp = gt_dir_str_temp{1}; % panel name
	gt_path_str_temp2 = gt_path_str_temp(1:end-1); % remove the slash
	gt_path_str_temp3 = replace(gt_path_str_temp2,data_str1,strcat(gt_str1,slsh));
	gt_path_str = strcat(gt_path_str_temp3,'.mat')
	dir_key_temp = split(gt_path_str_temp2,data_str1);
	dir_key = dir_key_temp{2};
	save_str1 = strcat("results",slsh,"GITRA_1106",slsh,dir_key,slsh);
    save_str = strcat(local_str, save_str1,file_name,slsh);
    if ~isfolder(save_str)
        mkdir(save_str)
    else
        continue; % skip the 
    end
    load(gt_path_str);
    gt_org_dmg_pts = org_ip_pc;
    gt_org_dmg_pts = RepeatRemove3D(gt_org_dmg_pts);
    %% filter the gt points to include points only from this sample
    gt_filter_bin = ismember(ip_point_cloud,gt_org_dmg_pts,'rows');
    gt_dmg_pts = gt_org_dmg_pts(gt_filter_bin,:);
    clear org_ip_pc
    clear gt_path_str
    ip_pc_avg_spc = AvgSpace3D(ip_point_cloud);
    clear filter_pc
    clear temp_ip_pts
%         time_per_step_vec = []; % time saving array
    %% STEP - I: Defining damaged points based on best nn and threshold multipliers
        neighb_struct_rad = struct;
        OutputPoints_struct_temp = struct;
        QuantAnalysis_struct_temp =  struct;
        AlgoAccuracy_pre_ref_max_vec = []; % store all max acc values for different nn radii
        nn_rad_vec = nn_mult_vec.*ip_pc_avg_spc;
        for nn_mult_itr = 1 : size(nn_mult_vec,1)
%             tic;
            neighb_struct_rad = KNNRadPF(ip_point_cloud,chunk_size,nn_rad_vec(nn_mult_itr));
            %% Initial Damage Point Labeling
            pre_ref_analysis_struct = struct;
            AlgoRecall_pre_ref = [];
            AlgoPrecision_pre_ref = [];
            AlgoF1Score_pre_ref = [];
            AlgoAccuracy_pre_ref = [];
            AlgoMCC_pre_ref = [];
            TPnum_pre_ref = [];
            FPnum_pre_ref = [];
            TNnum_pre_ref = [];
            FNnum_pre_ref = [];
            % extract only the relevant elements for threshold calculation
            temp_struct = struct;
            for itr_strct = 1 : size(neighb_struct_rad,2)
                temp_struct(itr_strct).num_nn = neighb_struct_rad(itr_strct).num_nn;
                temp_struct(itr_strct).eig_val_vec = neighb_struct_rad(itr_strct).eig_val_vec;
            end
            clear itr_strct
%             time_per_step_1temp1 = toc; % time taken for NN region extraction and setup
            parfor th_itr = 1 : size(ThrshMulFacArr,1)
                thresh_mul_fac = ThrshMulFacArr(th_itr);
                [damaged_points_cur,undamaged_points_cur,thresh_value_cur,...
                    time_elapsed_cur] = SVDamPtDetecNNipThreshMult...
                    (ip_point_cloud,temp_struct,thresh_mul_fac,chunk_size);
                pre_ref_analysis_struct(th_itr).ThreshValue = thresh_value_cur;
                pre_ref_analysis_struct(th_itr).DamagedPoints = damaged_points_cur;
                pre_ref_analysis_struct(th_itr).UndamagedPoints = undamaged_points_cur;
                pre_ref_analysis_struct(th_itr).TimeElapsed = time_elapsed_cur;
                % End of Damage Point Labeling
                % save the values of the quantitative metrics prior to refinement
                [AlgoRecall_pre_ref(th_itr,1),AlgoPrecision_pre_ref(th_itr,1)...
                    ,AlgoF1Score_pre_ref(th_itr,1),AlgoAccuracy_pre_ref(th_itr,1)...
                    ,AlgoMCC_pre_ref(th_itr,1),...
                    TPnum_pre_ref(th_itr,1),FPnum_pre_ref(th_itr,1),...
                    TNnum_pre_ref(th_itr,1),FNnum_pre_ref(th_itr,1)] = ...
                    QuantitativeAnalysisCFMV3(damaged_points_cur,...
                    undamaged_points_cur,gt_dmg_pts);
            end % end of iterating over threshold multipliers
            clear damaged_points_cur
            clear undamaged_points_cur
            clear thresh_value_cur
            clear time_elapsed_cur
            clear temp_struct
%             % time taken for looping over threshold multipliers
%             time_per_step_1temp2 = 0;
%             for time_itr = 1 : size(pre_ref_analysis_struct,2)
%                 time_per_step_1temp2 = time_per_step_1temp2 + ...
%                     pre_ref_analysis_struct(th_itr).TimeElapsed;
%             end
            % Best Damage Detection Result based on maximum Accuracy for different threshold multiplers
            [AlgoAccuracy_pre_ref_max_vec(nn_mult_itr,1),cur_opt_nn_idx]...
                = max(AlgoAccuracy_pre_ref);
            QuantAnalysis_struct_temp(nn_mult_itr).TPnum = TPnum_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).FPnum = FPnum_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).TNnum = TNnum_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).FNnum = FNnum_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).AlgoMCC = AlgoMCC_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).AlgoRecall = AlgoRecall_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).AlgoPrecision = AlgoPrecision_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).AlgoF1Score = AlgoF1Score_pre_ref(cur_opt_nn_idx);
            QuantAnalysis_struct_temp(nn_mult_itr).AlgoAccuracy = AlgoAccuracy_pre_ref(cur_opt_nn_idx);
            OutputPoints_struct_temp(nn_mult_itr).NNMultFact = nn_mult_vec(nn_mult_itr); 
            OutputPoints_struct_temp(nn_mult_itr).NNRadValue = nn_rad_vec(nn_mult_itr); 
            OutputPoints_struct_temp(nn_mult_itr).ThrshMultFact = ThrshMulFacArr(cur_opt_nn_idx);
            OutputPoints_struct_temp(nn_mult_itr).ThreshValue = pre_ref_analysis_struct(cur_opt_nn_idx).ThreshValue;
            OutputPoints_struct_temp(nn_mult_itr).DamagedPoints = pre_ref_analysis_struct(cur_opt_nn_idx).DamagedPoints;
            OutputPoints_struct_temp(nn_mult_itr).UndamagedPoints = pre_ref_analysis_struct(cur_opt_nn_idx).UndamagedPoints;
            clear pre_ref_analysis_struct;
            clear AlgoRecall_pre_ref;
            clear AlgoPrecision_pre_ref;
            clear AlgoF1Score_pre_ref;
            clear AlgoAccuracy_pre_ref;
            clear AlgoMCC_pre_ref;
            clear TPnum_pre_ref;
            clear FPnum_pre_ref;
            clear TNnum_pre_ref;
            clear FNnum_pre_ref;
%             time_per_step_1temp3 = toc; % time taken for data processing
%             time_per_step_vec(nn_mult_itr,1) = time_per_step_1temp2...
%                 + time_per_step_1temp1;
%             clear time_per_step_1temp3
            clear time_per_step_1temp2
            clear time_per_step_1temp1
        end % end of iterating over NN multipliers
        % Best Damage Detection Result based on maximum Accuracy for different NN radius multiplers
        [~,AlgoAccuracy_pre_ref_max_vec_idx] = max(AlgoAccuracy_pre_ref_max_vec);
        opt_param_vec(1,1) = nn_mult_vec(AlgoAccuracy_pre_ref_max_vec_idx); % NN radius multiplication factor
        opt_param_vec(2,1) = nn_rad_vec(AlgoAccuracy_pre_ref_max_vec_idx); % NN radius
        opt_param_vec(3,1) = OutputPoints_struct_temp(AlgoAccuracy_pre_ref_max_vec_idx).ThrshMultFact; % Th..multiplication factor
        opt_param_vec(4,1) = OutputPoints_struct_temp(nn_mult_itr).ThreshValue; % Thresh Value
        % consolidate variables and results
%         neighb_struct(ip_data_dir_itr) = neighb_struct_rad;
%         OutputPoints_struct(ip_data_dir_itr).data = OutputPoints_struct_temp;
%         OutputPoints_struct(ip_data_dir_itr).CFM = QuantAnalysis_struct_temp;
        OutputPoints_struct_opt(ip_data_dir_itr).data = OutputPoints_struct_temp...
            (AlgoAccuracy_pre_ref_max_vec_idx);
        OutputPoints_struct_opt(ip_data_dir_itr).CFM = QuantAnalysis_struct_temp...
        (AlgoAccuracy_pre_ref_max_vec_idx); 
        OutputPoints_struct_opt(ip_data_dir_itr).params = opt_param_vec;
        clear opt_param_vec;
        clear QuantAnalysis_struct_temp;
        clear OutputPoints_struct_temp;
        clear neighb_struct_rad
        clear AlgoAccuracy_pre_ref_max_vec
        clear AlgoAccuracy_pre_ref_max_vec_idx
        %% Step -II Iterative Refinement until convergence is observed 
        AlgoRecall_ref = [];
        AlgoPrecision_ref = [];
        AlgoF1Score_ref = [];
        AlgoAccuracy_ref = [];
        AlgoMCC_ref = [];
        TPnum_ref = [];
        FPnum_ref = [];
        TNnum_ref = [];
        FNnum_ref = [];
        algo_accuracy_vec = [];
        algo_mcc_vec = [];
        damaged_points_cur_ref = [];
        undamaged_points_cur_ref = [];
        OutputPoints_ref_struct = struct;
        QuantAnalysis_ref_struct = struct;
        rep_ct = 0; % counter for repetitions
%         time_per_iter = []; % 3 -steps
        for iter_itr = 1 : num_iter
%             tic;
            if rep_ct > 2
                break;
            end
            OutputPoints_struct_temp = struct;
            if iter_itr == 1
                % calculate the best threshold multipler by maximizing accuracy for best radius multipler based on prev. itertions
                % data retrival
                cur_struct_temp_opt = OutputPoints_struct_opt(ip_data_dir_itr).data;
                cur_struct_temp_quant = OutputPoints_struct_opt(ip_data_dir_itr).CFM;
                damaged_points_cur = cur_struct_temp_opt.DamagedPoints;
                undamaged_points_cur = cur_struct_temp_opt.UndamagedPoints;
                opt_param_vec = OutputPoints_struct_opt(ip_data_dir_itr).params;
                algo_accuracy_vec(iter_itr,1) = cur_struct_temp_quant.AlgoAccuracy;
                algo_mcc_vec(iter_itr,1) = cur_struct_temp_quant.AlgoMCC;
                OutputPoints_ref_struct(1).DamagedPoints = damaged_points_cur;
                OutputPoints_ref_struct(1).UndamagedPoints = undamaged_points_cur;
                QuantAnalysis_ref_struct(1).TPnum = cur_struct_temp_quant.TPnum;
                QuantAnalysis_ref_struct(1).FPnum = cur_struct_temp_quant.FPnum;
                QuantAnalysis_ref_struct(1).TNnum = cur_struct_temp_quant.TNnum;
                QuantAnalysis_ref_struct(1).FNnum = cur_struct_temp_quant.FNnum;
                QuantAnalysis_ref_struct(1).MCC = cur_struct_temp_quant.AlgoMCC;
                QuantAnalysis_ref_struct(1).Recall = cur_struct_temp_quant.AlgoRecall;
                QuantAnalysis_ref_struct(1).Precision = cur_struct_temp_quant.AlgoPrecision;
                QuantAnalysis_ref_struct(1).F1 = cur_struct_temp_quant.AlgoF1Score;
                QuantAnalysis_ref_struct(1).Accuracy = cur_struct_temp_quant.AlgoAccuracy;
                % 1st iteration of analysis
                avg_space_ip_pc = AvgSpace3D(damaged_points_cur); % determine the average point cloud
                nn_rad_ref_vec = avg_space_ip_pc.*nn_mult_vec_ref; % determine the NN radius based on previous analysis
                % calculate new NN regions for damaged points data
                OutputPoints_struct_temp_opt_th = struct; % store best threshold data for all NN values
%                 time_per_iter(iter_itr,1) = toc; % intial processing time
                for nn_mult_itr = 1 : size(nn_rad_ref_vec)
%                     tic;
                    neighb_struct_cur = KNNRadPF(damaged_points_cur,chunk_size,...
                        nn_rad_ref_vec(nn_mult_itr));
                    temp_struct = struct;
                    for itr_strct = 1 : size(neighb_struct_cur,2)
                        temp_struct(itr_strct).num_nn = neighb_struct_cur(itr_strct).num_nn;
                        temp_struct(itr_strct).eig_val_vec = neighb_struct_cur(itr_strct).eig_val_vec;
                    end
%                     time_per_iter(iter_itr,2) = toc; % NN extraction time
                    parfor th_itr = 1 : size(ThrshMulFacArr_ref,1)
                        damaged_points_cur_ref = [];
                        undamaged_points_cur_ref = [];
                        % refinement - perform thresholding again based on new NNs
                        [damaged_points_cur_ref,rem_points,time_elapsed] = ...
                            SVDamPtDetecNNipThreshMult(damaged_points_cur,temp_struct,...
                            ThrshMulFacArr_ref(th_itr),chunk_size); 
                        undamaged_points_cur_ref = [undamaged_points_cur;rem_points];
                        % quant analysis
                        [AlgoRecall_ref(th_itr,nn_mult_itr),...
                            AlgoPrecision_ref(th_itr,nn_mult_itr),...
                            AlgoF1Score_ref(th_itr,nn_mult_itr),...
                            AlgoAccuracy_ref(th_itr,nn_mult_itr)...
                            ,AlgoMCC_ref(th_itr,nn_mult_itr),...
                            TPnum_ref(th_itr,nn_mult_itr),...
                            FPnum_ref(th_itr,nn_mult_itr),...
                            TNnum_ref(th_itr,nn_mult_itr),...
                            FNnum_ref(th_itr,nn_mult_itr)] = ...
                            QuantitativeAnalysisCFMV3(damaged_points_cur_ref,...
                            undamaged_points_cur_ref,gt_dmg_pts);
                        OutputPoints_struct_temp(th_itr).DamagedPoints = damaged_points_cur_ref;
                        OutputPoints_struct_temp(th_itr).UndamagedPoints = undamaged_points_cur_ref;
                    end % end of parfor iterating over refinement threshold values
                    max_acc_val = max(AlgoAccuracy_ref(:,nn_mult_itr));
                    max_acc_val_bin = (AlgoAccuracy_ref(:,nn_mult_itr) == max_acc_val);
                    cur_opt_idx = max(find(max_acc_val_bin));
                    best_thmul_vec(nn_mult_itr,1) = ThrshMulFacArr_ref(cur_opt_idx);
                    best_thidx_vec(nn_mult_itr,1) = cur_opt_idx;
                    best_acc_vec(nn_mult_itr,1) = AlgoAccuracy_ref(cur_opt_idx,nn_mult_itr);
                    if size(fieldnames(OutputPoints_struct_temp_opt_th),1) > 1
                        OutputPoints_struct_temp_opt_th(nn_mult_itr) = OutputPoints_struct_temp(cur_opt_idx);
                    else
                        OutputPoints_struct_temp_opt_th = OutputPoints_struct_temp(cur_opt_idx);
                    end
                end % end of NN multiplier analysis
                % identify the best threshold multiplier based on the above
                max_acc_val = max(best_acc_vec);
                max_acc_val_bin = (best_acc_vec == max_acc_val);
                cur_opt_idx = max(find(max_acc_val_bin)); % best NN multi idx
                cur_th_opt_idx = best_thidx_vec(cur_opt_idx); % corresponding th multi idx
                opt_nn_mul_fact = nn_mult_vec_ref(cur_opt_idx);
                opt_th_mul_fact = best_thmul_vec(cur_opt_idx);
                damaged_points_cur_ref = OutputPoints_struct_temp_opt_th...
                    (cur_opt_idx).DamagedPoints;
                undamaged_points_cur_ref = OutputPoints_struct_temp_opt_th...
                    (cur_opt_idx).UndamagedPoints;
                opt_param_vec(5) = opt_nn_mul_fact; % Refinement NN.multiplication factor
                opt_param_vec(6) = opt_th_mul_fact; % Refinement Th..multiplication factor
                AlgoRecall_ref = AlgoRecall_ref(cur_th_opt_idx,cur_opt_idx);
                AlgoPrecision_ref = AlgoPrecision_ref(cur_th_opt_idx,cur_opt_idx);
                AlgoF1Score_ref = AlgoF1Score_ref(cur_th_opt_idx,cur_opt_idx);
                AlgoAccuracy_ref = AlgoAccuracy_ref(cur_th_opt_idx,cur_opt_idx);
                AlgoMCC_ref = AlgoMCC_ref(cur_th_opt_idx,cur_opt_idx);
                TPnum_ref = TPnum_ref(cur_th_opt_idx,cur_opt_idx);
                FPnum_ref = FPnum_ref(cur_th_opt_idx,cur_opt_idx);
                TNnum_ref = TNnum_ref(cur_th_opt_idx,cur_opt_idx);
                FNnum_ref = FNnum_ref(cur_th_opt_idx,cur_opt_idx);
                clear OutputPoints_struct_temp_opt_th
                clear cur_opt_idx
                clear best_thmul_vec
                clear best_acc_vec
                clear best_thmul_vec
                clear best_thidx_vec
                clear cur_opt_nn_idx
                clear cur_th_opt_idx
                clear max_acc_val
                clear max_acc_val_bin
                clear nn_mult_itr
                clear nn_rad_ref_vec
                clear opt_nn_mul_fact
                clear opt_th_mul_fact
                clear cur_struct_temp_quant
                clear cur_struct_temp_opt
            else
                % continue analysis with predetermined NN and threshold multipliers
                damaged_points_cur = damaged_points_cur_ref;
                undamaged_points_cur = undamaged_points_cur_ref;
                if size(damaged_points_cur,1) > 3
                    avg_space_ip_pc = AvgSpace3D(damaged_points_cur); 
                else
                    disp("Algorithm Terminated - dominance of labeled damage points");
                    break;
                end
                nn_rad_ref_vec = avg_space_ip_pc.*opt_param_vec(5); % determine the NN radius based on previous analysis
                % calculate new NN regions for damaged points data
                neighb_struct_cur = KNNRadPF(damaged_points_cur,chunk_size,...
                    nn_rad_ref_vec);
                temp_struct = struct;
                for itr_strct = 1 : size(neighb_struct_cur,2)
                    temp_struct(itr_strct).num_nn = neighb_struct_cur(itr_strct).num_nn;
                    temp_struct(itr_strct).eig_val_vec = neighb_struct_cur(itr_strct).eig_val_vec;
                end
                % refinement - perform thresholding again based on new NNs
                [damaged_points_cur_ref,rem_points] = ...
                    SVDamPtDetecNNipThreshMult(damaged_points_cur,temp_struct,...
                    opt_param_vec(6),chunk_size); 
                undamaged_points_cur_ref = [undamaged_points_cur;rem_points];
                % quant analysis
                [AlgoRecall_ref,AlgoPrecision_ref,AlgoF1Score_ref,...
                    AlgoAccuracy_ref,AlgoMCC_ref,TPnum_ref,...
                    FPnum_ref,TNnum_ref,FNnum_ref] = ...
                    QuantitativeAnalysisCFMV3(damaged_points_cur_ref,...
                    undamaged_points_cur_ref,gt_dmg_pts);
            end % end of first iteration conditional statement. common code below
            algo_accuracy_vec(iter_itr + 1,1) = AlgoAccuracy_ref;
            algo_mcc_vec(iter_itr +1,1) = AlgoMCC_ref;
            if size(damaged_points_cur_ref,1) == ...
                    size(OutputPoints_ref_struct(iter_itr).DamagedPoints,1)
                rep_ct = rep_ct + 1;
            end
            OutputPoints_ref_struct(iter_itr + 1).DamagedPoints = damaged_points_cur_ref;
            OutputPoints_ref_struct(iter_itr + 1).UndamagedPoints = undamaged_points_cur_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).TPnum = TPnum_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).FPnum = FPnum_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).TNnum = TNnum_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).FNnum = FNnum_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).MCC = AlgoMCC_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).Recall = AlgoRecall_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).Precision = AlgoPrecision_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).F1 = AlgoF1Score_ref;
            QuantAnalysis_ref_struct(iter_itr + 1).Accuracy = AlgoAccuracy_ref;
            clear AlgoRecall_ref;
            clear AlgoPrecision_ref;
            clear AlgoF1Score_ref;
            clear AlgoAccuracy_ref;
            clear AlgoMCC_ref;
            clear TPnum_ref;
            clear FPnum_ref;
            clear TNnum_ref;
            clear FNnum_ref;
            clear temp_struct;
            clear avg_space_ip_pc
            clear neighb_struct_cur
            clear rem_points
        end % end of iterative refinement
        %% Extract the best result after the iterative refinement
        rep_ct = 0;
        [~,opt_idx_cur_data] = max(algo_accuracy_vec);
        OutputPoints_ref_struct_opt(ip_data_dir_itr).nn_mult_ips = nn_mult_vec_str;
        OutputPoints_ref_struct_opt(ip_data_dir_itr).thrsh_mult_ips = thrsh_mult_vec_str;
        OutputPoints_ref_struct_opt(ip_data_dir_itr).data = OutputPoints_ref_struct(opt_idx_cur_data);
        OutputPoints_ref_struct_opt(ip_data_dir_itr).CFM = QuantAnalysis_ref_struct(opt_idx_cur_data);
        OutputPoints_ref_struct_opt(ip_data_dir_itr).params = opt_param_vec;
        mcc_acc_struct_full(ip_data_dir_itr).MCC = algo_mcc_vec; % save current sample mcc
        mcc_acc_struct_full(ip_data_dir_itr).Accuracy = algo_accuracy_vec; % save current sample acc
        save_file1 = OutputPoints_ref_struct_opt(ip_data_dir_itr);
        save_file2 = mcc_acc_struct_full(ip_data_dir_itr);
        disp(strcat("Saved in Local Drive for ",file_name," NN vals - ",strjoin(string(opt_param_vec),"_")));
%             end
        save(strcat(save_str,'op_struct_',string(num_iter),"_",nn_mult_vec_str,"_",thrsh_mult_vec_str),'save_file1','-v7.3')
        save(strcat(save_str,'mcc_acc_struct_',string(num_iter),"_",nn_mult_vec_str,"_",thrsh_mult_vec_str),'save_file2','-v7.3')
        
        clear save_file1
        clear save_file2
        clear OutputPoints_ref_struct
        clear algo_mcc_vec
        clear algo_accuracy_vec
        clear damaged_points_cur_ref
        clear damaged_points_cur
        clear undamaged_points_cur_ref
        clear undamaged_points_cur
        clear opt_idx_cur_data
        clear OutputPoints_ref_struct
       clear QuantAnalysis_ref_struct
        clear opt_param_vec
    end % end of iterating over all samples in current directory
end % end of iterating over input data source names
