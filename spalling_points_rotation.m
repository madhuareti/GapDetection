close all
clc
clear
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
%% Data parameters
rdrive_str = "\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\";
local_str="C:\Users\mareti\Desktop\local\";
data_str0 = strcat("data",slsh,"disaster_city",slsh);
data_str1 = strcat("damaged_points_comp_untrans",slsh); % data path inside upper level
rot_mat_dir0 = strcat(data_str0,"raw_data_complete",slsh,"transf_matrices",slsh);
rot_mat_dir = strcat(rdrive_str,rot_mat_dir0);
orient_data_dir = strcat("oriented_xyz",slsh);
orient_data_dir_str = strcat(rdrive_str,data_str0,"raw_data_complete",slsh,orient_data_dir);
save_str0 = strcat("damaged_points_complete",slsh);
save_str1 = strcat(rdrive_str,data_str0,save_str0);
ip_str = strcat(rdrive_str,data_str0,data_str1); % data path relative to local/rdrive str
%% Read data files
% extract all the files with .txt extension 
del_keys = [".";".."];
data_strs = CheckFolderSetup(ip_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
rot_data_strs_temp = dir(fullfile(rot_mat_dir));
rot_data_strs_struct = rot_data_strs_temp(~cellfun(@(x) MatchKeys(x, del_keys), {rot_data_strs_temp.name})); % paths of all directories (unique datasets)
rot_data_strs = [];
for itr = 1 : size(rot_data_strs_struct,1)
    rot_data_strs{itr} = rot_data_strs_struct(itr).name;
end
ornt_data_strs_temp = dir(fullfile(orient_data_dir_str));
ornt_data_strs_struct = ornt_data_strs_temp(~cellfun(@(x) MatchKeys(x, del_keys), {ornt_data_strs_temp.name})); % paths of all directories (unique datasets)
ornt_data_strs = [];
for itr = 1 : size(ornt_data_strs_struct,1)
    ornt_data_strs{itr} = ornt_data_strs_struct(itr).name;
end
for itr = 1 : size(data_strs,2)
    cur_data_path = data_strs(itr).val;
    % delete all the fillers observed in namins
    str_tag = split(cur_data_path,ip_str);
    str_tag = str_tag{2};
    str_tag = replace(str_tag,".mat","");
    str_tag = replace(str_tag,"_spallings","");
    str_tag = replace(str_tag,"_holes","");
    str_tag = replace(str_tag,"_hole","");
    % find a match for the string tag which is building_wall_panel_# format
    sum_bin = 0;
    for itr2 = 1 : size(rot_data_strs,2)
        temp_split = split(rot_data_strs{itr2},str_tag);
        if size(temp_split{1},1) == 0
            sum_bin = sum_bin + 1;
            cur_rot_data_str = rot_data_strs{itr2}; % corresponding tranform matrix
            break;
        else
            continue;
        end
    end
    % find a match in oriented xyz
    sum_bin = 0;
    for itr2 = 1 : size(ornt_data_strs,2)
        temp_split = split(ornt_data_strs{itr2},str_tag);
        if size(temp_split{1},1) == 0
            sum_bin = sum_bin + 1;
            cur_ornt_data_str = ornt_data_strs{itr2}; % corresponding tranform matrix
            break;
        else
            continue;
        end
    end
    % load the untransformed data and the transformational matrix
    if sum_bin > 0
        load(cur_data_path); % untransformed damaged points data 
        % convert mm to cm
        % convert 3 precision to 2 precision
        org_ip_pc = round(org_ip_pc,2); 
        org_ip_pc = org_ip_pc*100;
        rot_mat_dir_str = strcat(rot_mat_dir,cur_rot_data_str,slsh,"transf_mat.mat");
        load(rot_mat_dir_str); % load the transformation matrix
        ip_zero_cntrd = bsxfun(@minus, org_ip_pc, -best_trans_matrix(1:3,4)');
        ip_zero_cntrd = round(ip_zero_cntrd,3);
        orient_pts = best_trans_matrix(1:3,1:3)*ip_zero_cntrd';
        orient_pts = round(orient_pts',3);
        damaged_pts = orient_pts;
        damaged_pts = RepeatRemove3D(damaged_pts);
        clear orient_pts;
        save_str = strcat(save_str1,cur_rot_data_str,".mat");
        save(save_str,'damaged_pts','-v7.3');
%         % load oriented panel data
%         orient_data_str = strcat(orient_data_dir_str,cur_ornt_data_str);
%         load(orient_data_str);
%         panel_pc = filter_pc;
%         clear filter_pc
%         figure; plot3(panel_pc(:,1),panel_pc(:,2),panel_pc(:,3),'.'); hold on;
%         plot3(damaged_pts(:,1),damaged_pts(:,2),damaged_pts(:,3),'.');
    else
        continue;
    end
end