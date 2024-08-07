low_lim_vec = [1, 2, 3; ]; % xyz lower limits
up_lim_vec = [4, 5, 6; ]; % xyz upper limits
org_gt_damaged_point_struct = struct;
for itr = 1 : size(low_lim_vec,1)
    binx = org_ip_pc(:,1) >= low_lim_vec(itr,1) && org_ip_pc(:,1) <= up_lim_vec(itr,1); % x or y
    biny = org_ip_pc(:,2) >= low_lim_vec(itr,2) && org_ip_pc(:,2) <= up_lim_vec(itr,2); % x or y
    binz = org_ip_pc(:,3) >= low_lim_vec(itr,3) && org_ip_pc(:,3) <= up_lim_vec(itr,3); % z
    data_bin = binx && biny && binz;
    org_gt_damaged_point_struct(itr).data = org_ip_pc(data_bin,:);
end
min(org_ip_pc(:,1))