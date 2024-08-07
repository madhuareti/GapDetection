clc
clear
close all
local_str = "C:\Users\mareti\Desktop\local\";
rdrive_str = "\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\";
dir_str = "results\oriented_xyz_ws_zb";
gt_str1 = "data\disaster_city\damaged_points_complete";
img_save_str1 = "results\hrimages\oriented_xyz_ws_zb";
% save_str_key='csv_files';
% defining if linux or windows for "/" or "\" usage
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
% dir_str1 = strcat("data",slsh,"disaster_city",slsh,"sample_data_complete",slsh);
% save_dir = strcat(rdrive_str,dir_str1,dir_str,slsh,save_str_key,slsh);
dir_str1 = [];
device_dir_str = strcat(local_str,dir_str1,dir_str,slsh);
file_type = ".mat"; % only extract values with this extension
del_keys = [".";".."]; % delete files with this extension
keep_keys1 = "stp2"; % only extract values with this key in file name
keys_struct = struct; % combine both keys for input
keys_struct(1).value = del_keys;
keys_struct(2).value = keep_keys1;
bin_struct = struct; % combine both operation values for input
bin_struct(1).value = "delete";
bin_struct(2).value = "keep";
mat_strs = FileExtractDirAll(device_dir_str,bin_struct,keys_struct,file_type,slsh);
if size(mat_strs,1) <= 1
    disp("!!!!! No files found !!!!!");
    return
end

for itr = 1 : size(mat_strs,1)
   % code for plotting data
%     file_name = mat_strs(itr).name;
%     file_key = split(file_name,'.mat');
%     file_key = file_key{1};
%     path = strcat(mat_strs(itr).folder,slsh,file_key);
%     load(path);
%     plot3(cartographic_result(:,1),cartographic_result(:,2),...
%         cartographic_result(:,3),'.');
%     hold on
    % code for plotting results
    path = strcat(mat_strs(itr).folder,slsh,mat_strs(itr).name);
    dir_key_temp = split(mat_strs(itr).folder,dir_str);
    dir_key_temp2 = split(dir_key_temp{2},slsh);
    dir_key = dir_key_temp2{2};
    gt_key = replace(dir_key,"_200","");
    load(path);
    gt_str = strcat(local_str,slsh,gt_str1,slsh,gt_key,'.mat');
    load(gt_str);
    gt_dmg_pts = org_ip_pc;
    clear org_ip_pc
    figure
    undmg = stp2_pts_res.undamaged_points;
    dmg = stp2_pts_res.damaged_points;
    plot3(undmg(:,1),undmg(:,2),undmg(:,3),'b.')    
%     hold on
%     plot3(dmg(:,1),dmg(:,2),dmg(:,3),'r.')
    hold on
    plot3(dmg(:,1),dmg(:,2),dmg(:,3),'b.')
    hold on
    plot3(gt_dmg_pts(:,1),gt_dmg_pts(:,2),gt_dmg_pts(:,3),'k.')

    title(string(dir_key), 'Interpreter','none')
    xlabel('X(cm)')
    ylabel('Y(cm)')
    zlabel('Z(cm)')
    % setting view point - check what axis represents the thickness 
    if abs(max(gt_dmg_pts(:,2))) > abs(max(gt_dmg_pts(:,1)))
        % thickenss along X axis
        view([180 0 0])
    else % thickenss along Y axis
        view([0 180 0])
    end
    img_dir_str = strcat(local_str,img_save_str1,slsh);
    if ~isfolder(img_dir_str)
        mkdir(img_dir_str);
    end
    img_save_str  = strcat(img_dir_str,dir_key,'_gt_front.jpg');
    exportgraphics(gcf,img_save_str,'Resolution',600);
    close all
end