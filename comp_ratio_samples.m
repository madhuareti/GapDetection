clc
clear
close all
local_str = "C:\Users\mareti\Desktop\local\";
rdrive_str = "\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\";
save_str1 = "comp_ratio";
% save_str_key='csv_files';
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
dir_str1 = strcat("data",slsh,"disaster_city",slsh,"sample_data_complete_1007",slsh);
gt_str1 = strcat("data",slsh,"disaster_city",slsh,"damaged_points_complete",slsh);
org_str1 = strcat("data",slsh,"disaster_city",slsh,"raw_data_complete",slsh,"oriented_xyz",slsh);
dir_str = [];
save_dir = strcat(local_str,dir_str1,dir_str);
device_dir_str = strcat(local_str,dir_str1,dir_str);
file_type = ".mat"; % only extract values with this extension
del_keys = [".";".."]; % delete files with this extension
keys_struct = struct; % combine both keys for input
keys_struct(1).value = del_keys;
bin_struct = struct; % combine both operation values for input
bin_struct(1).value = "delete";
mat_strs = FileExtractDirAll(device_dir_str,bin_struct,keys_struct,file_type,slsh);
mat_strs_full = mat_strs;
if size(mat_strs,1) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
% extract all the panel names in the data
res_ct = 1;
panel_key_arr = [];
while max(size(mat_strs,1)) > 1
    path = strcat(mat_strs(1).folder,slsh,mat_strs(1).name);
    dir_key_temp = split(mat_strs(1).folder,dir_str1);
    dir_key_temp2 = split(dir_key_temp{2},slsh);
    try
        panel_key = dir_key_temp2{2};
    catch
        panel_key = dir_key_temp2{1};
    end
    mat_strs(1) = [];
    if sum(ismember(panel_key_arr,panel_key))
        continue
    else
        panel_key_arr{res_ct,1} = panel_key;
        res_ct = res_ct + 1;
    end  
    % find all the results from the current sample
end
for itr = 1 : size(panel_key_arr,1)
    panel_key = panel_key_arr{itr};
    dir_strs_bin = cellfun(@(x) MatchKeys(x, panel_key),...
            {mat_strs_full.folder});
    dir_strs_bin2 = find(dir_strs_bin);
    dir_strs = mat_strs_full(dir_strs_bin2);
    % load gt data
    gt_path_str = strcat(local_str,gt_str1,panel_key,'.mat');
    org_path_str = strcat(local_str,org_str1,panel_key,'.mat');
    try
        load(gt_path_str);
        gt_dmg_pts = org_ip_pc;
        clear org_ip_pc
    catch 
        disp("Ground Truth Not Found at ");
        gt_path_str
        continue;
    end
    try
        load(org_path_str);
        raw_pts = filter_pc;
        clear filter_pc
    catch 
        disp("Raw Point Cloud Not Found at ");
        org_path_str
        continue;
    end
    stat_struct = struct;
    for itr2 = 1 : max(size(dir_strs))
        load(strcat(dir_strs(itr2).folder,slsh,dir_strs(itr2).name));
        ip_data = cartographic_result;
        dmg_bin = ismember(ip_data,gt_dmg_pts,"rows"); % all dmg from gt in sampled pc
        dmg_pts = ip_data(find(dmg_bin));%#ok<FNDSB>
        undmg_pts = ip_data(find(~dmg_bin));%#ok<FNDSB>
        stat_struct(itr2).panel_id = panel_key;
        stat_struct(itr2).sample_id = dir_strs(itr2).name;
        stat_struct(itr2).raw_data = size(raw_pts,1);
        stat_struct(itr2).gt_dmg = size(gt_dmg_pts,1);
        stat_struct(itr2).gt_undmg = stat_struct(itr2).raw_data - stat_struct(itr2).gt_dmg;
        stat_struct(itr2).sampled_data = size(cartographic_result,1);
        stat_struct(itr2).sampled_dmg = size(dmg_pts,1);
        stat_struct(itr2).sampled_undmg = size(undmg_pts,1);
    end
    try
    	writetable(struct2table(stat_struct),strcat(save_dir,panel_key,slsh,'stats_',panel_key,".csv"));
    catch err
	    disp("Error Saving the .csv file");
	    panel_key
    end
end