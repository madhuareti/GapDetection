clc
clear
close all
local_str = "C:\Users\mareti\Desktop\local\";
rdrive_str = "\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\";
dir_str = "raw_data_complete\oriented_xyz";
save_str_key='csv_files';
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
dir_str1 = strcat("data",slsh,"disaster_city",slsh);
save_dir = strcat(rdrive_str,dir_str1,dir_str,slsh,save_str_key,slsh);
device_dir_str = strcat(rdrive_str,dir_str1,dir_str,slsh);
del_keys = [".";".."]; % delete files with this extension
keep_keys = ".mat"; % only extract values with this extension
keys_struct = struct; % combine both keys for input
keys_struct(1).value = del_keys;
keys_struct(2).value = keep_keys;
bin_struct = struct; % combine both operation values for input
bin_struct(1).value = "delete";
bin_struct(2).value = "keep";
mat_strs = FileExtractDir(device_dir_str,bin_struct,keys_struct);
if size(mat_strs,1) <= 1
    disp("!!!!! No files found !!!!!");
    return
end
if ~isfolder(save_dir)
    mkdir(save_dir);
end
for itr = 1 : size(mat_strs,1)
    file_name = mat_strs(itr).name;
    file_key = split(file_name,'.mat');
    file_key = file_key{1};
    path = strcat(mat_strs(itr).folder,slsh,file_key);
    load(path);
    save_str = strcat(save_dir,file_key,".txt");
    cur_table = table(filter_pc(:,1),filter_pc(:,2),...
        filter_pc(:,3),'VariableNames',{'X','Y','Z'});
    try
    	writetable(cur_table,save_str);
    catch err
	    disp("Error Saving the .csv file");
    end
end