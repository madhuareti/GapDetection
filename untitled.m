cur_data_struct = save_file1.data;
damaged_points_res = cur_data_struct.DamagedPoints;
plot3(damaged_points_res(:,1),damaged_points_res(:,2),damaged_points_res(:,3),'.')

damaged_points_res = stp2_pts_res.damaged_points;
plot3(damaged_points_res(:,1),damaged_points_res(:,2),damaged_points_res(:,3),'.')
undamaged_points_res = stp2_pts_res.undamaged_points;
hold on
plot3(undamaged_points_res(:,1),undamaged_points_res(:,2),undamaged_points_res(:,3),'.')



for itr = 1 : size(org_gt_damaged_point_struct,2)
    cur_data = org_gt_damaged_point_struct(itr).data;
    plot3(cur_data(:,1),cur_data(:,2),cur_data(:,3),'.')
    hold on
end
org_gt_damaged_point_struct(5,6).data = []

org_gt_damaged_point_struct_temp = org_gt_damaged_point_struct;
org_gt_damaged_point_struct = struct;
for itr = 1 : size(org_gt_damaged_point_struct_temp,2) -2
     org_gt_damaged_point_struct(itr).data = org_gt_damaged_point_struct_temp(itr).data;
end