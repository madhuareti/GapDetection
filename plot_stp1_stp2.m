
for itr1 = 1 : size(stp1_struct_struct,2)
    cur_nn_num_struct = stp1_struct_struct(itr1).data;
    for itr2 = 1 : size(cur_nn_num_struct,2)
        cur_nnn_ip_data_struct = cur_nn_num_struct(itr2).data;
        if size(cur_nnn_ip_data_struct,2) ~= 0 
            dmg_pts = cur_nnn_ip_data_struct.damaged_points;
            un_dmg_pts = cur_nnn_ip_data_struct.undamaged_points;
            figure
            plot3(dmg_pts(:,1),dmg_pts(:,2),dmg_pts(:,3),'b.');
            hold on
            plot3(un_dmg_pts(:,1),un_dmg_pts(:,2),un_dmg_pts(:,3),'k.');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
    end
end
for itr1 = 1 : size(stp1_struct_struct,2)
    cur_nn_num_struct = stp1_struct_struct(itr1).data;
    for itr2 = 1 : size(cur_nn_num_struct,2)
        cur_nnn_ip_data_struct = cur_nn_num_struct(itr2).data;
        if size(cur_nnn_ip_data_struct,2) ~= 0 
            dmg_pts = cur_nnn_ip_data_struct.damaged_points;
            un_dmg_pts = cur_nnn_ip_data_struct.undamaged_points;
            figure
            plot3(dmg_pts(:,1),dmg_pts(:,2),dmg_pts(:,3),'b.');
            hold on
            plot3(un_dmg_pts(:,1),un_dmg_pts(:,2),un_dmg_pts(:,3),'k.');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
        end
    end
end