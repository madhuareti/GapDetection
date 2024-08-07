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
% folder_key = "damaged_points_complete";
folder_key = strcat("raw_data_complete",slsh,"oriented_xyz");
data_str1 = strcat("data",slsh,"disaster_city",slsh,folder_key,slsh); % data path inside upper level
save_str1 = strcat(local_str,"data",slsh,"disaster_city",slsh,"sample_data_complete",slsh);
ip_str = strcat(local_str,data_str1); % data path relative to local/rdrive str
%% Read data files
% extract all the files with .txt extension 
del_keys = [".";".."];
data_strs = CheckFolderSetup(ip_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
for itr = 1 : size(data_strs,2)
    cur_file = data_strs(itr).val;
%     file_key1 = split(cur_file,strcat("oriented_xyz",slsh));
%     file_key2 = split(file_key1{2},".mat");
    file_key1 = split(cur_file,strcat(folder_key,slsh));
    file_key2 = split(file_key1{2},".mat");
    file_key{itr,1} = file_key2{1};
    load(data_strs(itr).val);
%     xy_box = polyshape(filter_pc(:,1),filter_pc(:,2));
%     [xlim1,ylim1] = boundingbox(xy_box);
%     xz_box = polyshape(filter_pc(:,1),filter_pc(:,3));
%     [xlim2,zlim1] = boundingbox(xz_box);
%     yz_box = polyshape(filter_pc(:,2),filter_pc(:,3));
%     [ylim2,zlim2] = boundingbox(yz_box);
%     cube_dim_x = [min(xlim1(1),xlim2(1)),max(xlim1(2),xlim2(2))];
%     cube_dim_y = [min(ylim1(1),ylim2(1)),max(ylim1(2),ylim2(2))];
%     cube_dim_z = [min(zlim1(1),zlim2(1)),max(zlim1(2),zlim2(2))];
%     cube_dim = [cube_dim_x;cube_dim_y;cube_dim_z];
% %     plot3(filter_pc(:,1),filter_pc(:,2),filter_pc(:,3),'.');sz
% %     hold on 
% %     plot3(cube_dim(1,:),cube_dim(2,:),cube_dim(3,:),'r*');
%     clear xy_box;
%     clear xz_box;
%     clear yz_box;
%     box_vol_vec(itr,1) = abs((cube_dim(1,2) - cube_dim(1,1)))*...
%         abs((cube_dim(2,2) - cube_dim(2,1)))*...
%         abs((cube_dim(3,2) - cube_dim(3,1)));
%     dens_vec(itr,1) = box_vol_vec(itr,1)/size(filter_pc,1);
    num_vec(itr,1) = size(filter_pc,1);
%     damaged_pts = RepeatRemove3D(damaged_pts);
%     num_vec(itr,1) = size(damaged_pts,1);
%     num_vec(itr,1) = size(org_ip_pc,1);
    clear filter_pc;
end