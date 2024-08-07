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
res_key = "pa_11_08";
% res_key = "oitra_10_13";
% res_key = "gitra_11_06";
dir_str = strcat("results",slsh,"quant_results",slsh,res_key,slsh);
device_dir_str = strcat(local_str,dir_str);
del_keys = [".";".."];
data_strs = CheckFolderSetup(device_dir_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
data_strs_loop = reshape(struct2cell(data_strs),size(data_strs,2),1);
% analyze only op struct results
keep_key = "_cfm_mgiou_results";
cur_sample_bin = cellfun(@(x) MatchKeys(x, keep_key), data_strs_loop);
data_strs_loop = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
disp(strcat("there are ",string(size(data_strs_loop,1)),' files/subdirectories in this directory'));
comp_quant_struct = struct;
qt_ct = 0;
while min(size(data_strs_loop)) >= 1
    % find all results from single iteration
    cur_path = data_strs_loop{1};
    param_key_temp1 = split(cur_path,device_dir_str);
    param_key_temp2 = split(param_key_temp1{2},'.mat');
    if size(param_key_temp2,1) > 1
    param_key_temp3 = split(param_key_temp2{1},slsh);
        if isempty(param_key_temp3) % if all elements are empty 
            data_strs_loop(1) =[];
            continue
        else
            param_key1_temp1 = split(param_key_temp3{end},keep_key);
            param_key1_temp2 = split(param_key1_temp1{1},"_");
            param_key1 = strjoin(param_key1_temp2(1:3),"_");
            if size(param_key1_temp2,1) > 3
                if strcmp(param_key1_temp2{4},'hole')
                    param_key1 = strcat(param_key1,"_",param_key1_temp2{4});
                else
                    param_key2 = strjoin(param_key1_temp2(4:end),"_");
                    param_key2 = strcat("sample_",param_key2);
                end
            else
                param_key2 = [];
            end
        end
    else
        data_strs_loop(1) =[];
        continue
    end
    % find all the results from the current sample
    cur_sample_bin = cellfun(@(x) MatchKeys(x, param_key1), data_strs_loop);
    cur_sample_list = data_strs_loop(find(cur_sample_bin)); %#ok<FNDSB> 
    data_strs_loop = data_strs_loop(find(~cur_sample_bin)); %#ok<FNDSB> 
    samp_ct = 1;
    while ~isempty(cur_sample_list{samp_ct})
        samp_ct = samp_ct + 1;
        % find all the results for the current sample and current parameters
        try
            load(cur_sample_list{1})
            cur_sample_list{samp_ct} = [];
        catch
            disp('result not found')
            strcat(param_key1,param_key2)
            cur_sample_list{samp_ct} = [];
            continue;
        end % end of try catch for loading the current result
        qt_ct = qt_ct + 1;
        comp_quant_struct(qt_ct).panel_id = param_key1;
        comp_quant_struct(qt_ct).sample_id = param_key2;
        comp_quant_struct(qt_ct).TP = TP_num_vec;
        comp_quant_struct(qt_ct).FP = FP_num_vec;
        comp_quant_struct(qt_ct).TN = TN_num_vec;
        comp_quant_struct(qt_ct).FN = FN_num_vec;
        comp_quant_struct(qt_ct).MCC = AlgoMCC_vec;
        comp_quant_struct(qt_ct).mGIoU = giou_struct.mgiou;
        comp_quant_struct(qt_ct).ACC = AlgoAccuracy_vec;
        comp_quant_struct(qt_ct).F1 = AlgoF1Score_vec;
        comp_quant_struct(qt_ct).Precision = AlgoPrecision_vec;
        comp_quant_struct(qt_ct).Recall = AlgoRecall_vec;
    end % end of while loop for current panel
end % end of while loop for all the panels in the directory
save_str = strcat(dir_str,res_key,"_comp_quant.mat");
save(save_str,"comp_quant_struct",'-v7.3')