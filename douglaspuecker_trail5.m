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
% data_str1 = strcat("raw_data_complete",slsh,"mat_xyz",slsh); % data path inside upper level
data_str1 = strcat("raw_data",slsh,"panel1",slsh); % data path inside upper level
save_str0 = strcat("sample_data_complete",slsh);
save_str00 = strcat("raw_data_complete",slsh);
save_str1 = strcat(rdrive_str,data_str0,save_str0);
save_str001 = strcat(rdrive_str,data_str0,save_str00);
ip_str = strcat(rdrive_str,data_str0,data_str1); % data path relative to local/rdrive str
%% Algorithm parameters
rect_wall_thick = 4*2.54; % 4inch thick
% set slicing width and tolerance vector values
% slce_wid = 10; % val = 1, if maintain the 1cm slice width for analysis
slce_wid_vec = 1:10;
max_tol = 2;
tol_val_vec = 0.1:0.1:max_tol;
vec_ct = 0; % counter for possible combinations
slce_tol_vec = [];
% only consider tolerance values between [min,max] multiplier
tol_mult = [0,0.1]; %0.1 is observed from intial set of experiments
%% Read data files
% extract all the files with .txt extension 
del_keys = [".";".."];
data_strs = CheckFolderSetup(ip_str,del_keys,slsh,'.mat');
if size(data_strs,2) <= 1
    disp("!!!!! No files found !!!!!");
    disp("!!!!! Check if Path Input is Valid and is Reachable !!!!!");
    return
end
%% Process individual files
for itr = 1 : size(data_strs,2)
    cur_data_path = data_strs(itr).val;
    str_tag_temp = split(cur_data_path,data_str1);
    str_tag = str_tag_temp{2};
    str_tag = replace(str_tag,".mat",""); % file name
    save_str = strcat(save_str1,str_tag); % directory for all subsamples
    load(cur_data_path);
    % convert m to cm for matlab processing
    org_ip_pc = round(org_ip_pc,2);
    org_ip_pc = RepeatRemove3D(org_ip_pc);
    % convert 3 precision to 2 precision
    ip_pts = org_ip_pc*100;
    for itr1 = 1 : size(slce_wid_vec,2)
        skip_ct = 1;
        for itr2 = 1 : size(tol_val_vec,2)
            if tol_val_vec(itr2) < tol_mult(1)*slce_wid_vec(itr1)
                continue;
            end
            if tol_val_vec(itr2) >= tol_mult(2)*slce_wid_vec(itr1)
                if skip_ct && itr2 == 1 % save one val
                    skip_ct = 0;
                    vec_ct = vec_ct + 1;
                    slce_tol_vec(vec_ct,1) = slce_wid_vec(itr1);
                    slce_tol_vec(vec_ct,2) = tol_val_vec(itr2);
                else
                    break;
                end
            else
                vec_ct = vec_ct + 1;
                slce_tol_vec(vec_ct,1) = slce_wid_vec(itr1);
                slce_tol_vec(vec_ct,2) = tol_val_vec(itr2);
            end
        end
    end
    %% data transformation
    mean_pt_org = mean(ip_pts,1);
    pc_zero_cntrd = bsxfun(@minus, ip_pts, mean_pt_org);  
    % pc_zero_cntrd = ip_pts;
    pc_zero_cntrd = round(pc_zero_cntrd,3);
    mean_pt = mean(pc_zero_cntrd,1);
    pca_vecs = pca(pc_zero_cntrd);
    % Only taking rotation along Z axis as Z-data == true Z
    % consider only the vectors with non dominant Z coordinate value
    theta_ct = 1;
    for itr1 = 1: 3
        [~,idx] = max(abs(pca_vecs(:,itr1)));
        axes_vec = zeros(1,3);
        if idx ~=3
            axes_vec(idx) = 1;
            theta(itr1,1) = acosd(dot(pca_vecs(:,itr1),axes_vec));
            theta(itr1,2) = idx;
            theta_ct = theta_ct + 1;
        end
    end
    % rotate the data aroud Z axis (because of all points are perpendicular with Z)
    % save rotation that maximizes sum of dominant values of princ. comps.
    orient_pts_struct = struct;
    rot_struct = struct; % save the rotation matrices
    for itr1 = 1 : size(theta,1)
        if theta(itr1,1) ~= 0
            R = rotz(theta(itr1,1));
            orient_pts = R*pc_zero_cntrd';
            orient_pts_struct(itr1).data = orient_pts';
            cur_pca_vecs = pca(orient_pts');
            max_vec = max(cur_pca_vecs); % dominant values for each pc
            sum_vec(itr1) = sum(max_vec);
            rot_struct(itr1).val = R;
        end
    end
    [~,idx] = max(sum_vec);
    orient_pts = orient_pts_struct(idx).data;
    trans_matrix = eye(4,4);
    trans_matrix(1:3,1:3) = rot_struct(idx).val;
    trans_matrix(1:3,4) = -mean_pt_org;
    % xlim = 10;
    % xlim_bin = orient_pts(:,1) >= xlim;
    xlim_bin = zeros(size(orient_pts,1),1);
    filter_pc = orient_pts(~xlim_bin,:);
    filter_pc = round(filter_pc,3);
    filter_pc = RepeatRemove3D(filter_pc);       
    % plot3(filter_pc(:,1),filter_pc(:,2),filter_pc(:,3),'.')
%     save_dir_str1 = strcat(save_str001,slsh,"oriented_xyz",slsh);
%     save_dir_str2 = strcat(save_str001,slsh,"transf_matrices",slsh);
%     if ~isfolder(save_dir_str1)
%         mkdir(save_dir_str1);
%     end
%     if ~isfolder(save_dir_str2)
%         mkdir(save_dir_str2);
% %     end
%     trans_data_save_str = strcat(save_dir_str1,str_tag,".mat");
%     save(trans_data_save_str,'filter_pc','-v7.3');
%     trans_mat_save_str = strcat(save_dir_str2,str_tag,".mat");
%     save(trans_mat_save_str,'trans_matrix','-v7.3');
%     continue;
    %% 3D Slicing
    % Douglas-Pueker sampling is performed on XZ and XY space because spalling is
    % along X direction
    sampling_struct = struct; % save the parameters for quantifying the sampling results
    %%%%%%%%%%%%%%%%%%% slice along the Y direction %%%%%%%%%%%%%%%%%%%
    for itr1 = 1: size(slce_tol_vec,1)
        [sample_result_xz,data_bin_xz] = SmplngDougPeuck(filter_pc,slce_tol_vec(itr1,2),[1,3],slce_tol_vec(itr1,1));
        [sample_result_xy,data_bin_xy] = SmplngDougPeuck(filter_pc,slce_tol_vec(itr1,2),[1,2],slce_tol_vec(itr1,1));
        cartographic_result = filter_pc(~(~data_bin_xz | ~data_bin_xy),:);
        if size(cartographic_result,1) > 0
            save_str_final = strcat(save_dir_str,slsh,"sample_",string(slce_tol_vec(itr1,1)),...
                "_",strrep(string(round(slce_tol_vec(itr1,2),2)),'.',''),'.mat');
            save(save_str_final,'cartographic_result','-v7.3');
        else
            continue;
        end
        sampling_struct(itr1).slice_wid = slce_tol_vec(itr1,1);
        sampling_struct(itr1).tol_dp = slce_tol_vec(itr1,2);
        sampling_struct(itr1).ip_ct = size(filter_pc,1);
        sampling_struct(itr1).res_ct = size(cartographic_result,1); 
        sampling_struct(itr1).comp_ratio = size(cartographic_result,1)/size(filter_pc,1); 
        clear cartographic_result;
    end
    writetable(struct2table(sampling_struct),strcat(save_dir_str,slsh,'params_',str_tag,".csv"));
    % figure
    % plot3(cartographic_result(:,1),cartographic_result(:,2),cartographic_result(:,3),'k.')
end