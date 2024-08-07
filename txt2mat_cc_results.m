close all
clc
clear
% sampl_str = 'raw_data\panel1\';
% txt_str = 'damaged_points.txt';
% mat_str = 'damaged_points.mat';
% txt_str = 'point_cloud.txt';
% mat_str = 'point_cloud.mat';
% txt_str = 'panel1_filt_1cmres.txt';
% mat_str = 'panel1_filt_1cmres.mat';
slash_key = 'windows';
switch slash_key
    case 'linux'
        slsh = '/';
    case 'windows'
        slsh = '\';
end
rdrive_str = '\\coe-fs.engr.tamu.edu\research\MEEN\Hasnain_Zohaib\Students\Areti_Madhu_Dhana\GapDetection\3d_point_cloud_geometry\GapDetect\';
local_str = "C:\Users\mareti\Desktop\local\";
data_str_temp = strcat("data",slsh,"disaster_city",slsh,"raw_data_complete",slsh); % data path inside upper level
save_str_temp = strcat(data_str_temp,"damaged_points_comp_untrans_all",slsh);
% save_str_temp = strcat(data_str_temp,slsh,"mat_xyz",slsh);
data_str =strcat(data_str_temp,"xyz",slsh); % data string
ip_str = strcat(rdrive_str,data_str); % data path relative to local/rdrive str
del_keys = [".";".."];
% extract all the files with .txt extension 
data_strs = CheckFolderSetup(ip_str,del_keys,slsh,'.txt');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
%% Quantitative Analysis
% extract all the files with relevant data == only concrete panels
keep_keys = ["_spallings","hole"];
data_strs = reshape(struct2cell(data_strs),size(data_strs,2),1);
temp_bin = logical(cellfun(@(x) MatchKeys(x, keep_keys), data_strs));
data_strs_filter = data_strs(temp_bin);
disp(strcat("there are ",string(size(data_strs_filter,1)),' files/subdirectories in this directory'));
for itr = 1 : size(data_strs_filter,1)
    txt_data_str = data_strs_filter{itr};
    % read the text file
    txt_data_str_temp = replace(txt_data_str,".txt","");
    txt_data_str_temp = split(txt_data_str_temp,"_spallings");
    txt_data_str_temp = split(txt_data_str_temp{1},"_holes");
    txt_data_str_temp = split(txt_data_str_temp{1},"_hole");
    txt_data_str_temp = split(txt_data_str_temp{1},"_with");
    keep_keys = txt_data_str_temp{1};
    temp_bin = logical(cellfun(@(x) MatchKeys(x, keep_keys), data_strs));
    txt_data_strs = data_strs(temp_bin); % all paths with current string
    keep_keys = ["_concrete","metal"];
    temp_bin = logical(cellfun(@(x) MatchKeys(x, keep_keys), txt_data_strs));
    txt_data_str = txt_data_strs(~temp_bin); % all paths without current string
    if size(txt_data_str,1) == 0
        continue;
    end
    for itr2 = 1 : size(txt_data_str,1)
        temp_ip_pc = dlmread(txt_data_str{itr2});
        if size(temp_ip_pc,2) > 3
            org_ip_pc = temp_ip_pc(:,1:3); % elimintae the normals columns
        else
            org_ip_pc = temp_ip_pc;
        end
        clear temp_ip_pc;
        sample_str_temp = split(txt_data_str{itr2},ip_str);
        sample_str_temp2 = split(sample_str_temp{2},slsh);
        sample_str_temp3 = split(sample_str_temp2{2},".txt");
        sample_str = sample_str_temp3{1};
        sample_str = lower(sample_str);
        sample_str = replace(sample_str,"-","_");
        sample_str = replace(sample_str,"building_","b");
        sample_str = replace(sample_str,"buiding_","b");
        sample_str = replace(sample_str,"wall_","w");
        sample_str = replace(sample_str,"panel_","p");
        sample_str = replace(sample_str,"panel","p");
        sample_str = replace(sample_str,"_concrete","");
        sample_str = replace(sample_str,"with_","");
        sample_str = replace(sample_str," ","");
        % if a panel has both spallings and holes, keep the tags
        if max(size(split(sample_str,"_spallings"))) > 1 && ...
                max(size(split(sample_str,"_hole"))) > 1
        else
            % remove spalling defect, if otherwise
            sample_str = replace(sample_str,"_spallings","");
        end
        save_dir_str = strcat(rdrive_str,save_str_temp);
        if ~isfolder(save_dir_str)
            mkdir(save_dir_str);
        end
        save_str = strcat(save_dir_str,sample_str,'.mat')
        save(save_str,'org_ip_pc','-v7.3');
        % plot3(org_ip_pc(:,1),org_ip_pc(:,2),org_ip_pc(:,3),'.')
    end % end of iterating over the data samples for the current key word
end