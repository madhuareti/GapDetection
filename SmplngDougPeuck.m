% sub sample point cloud data using Douglas Peucker algorithm
function [sample_result,data_bin] = SmplngDougPeuck(ip_data,epsilon,axes_info,slice_width)
    axes_vec = 1:size(ip_data,2);
    slice_axis_bin = ismember(axes_vec,axes_info);
    slice_axis = axes_vec(~slice_axis_bin);
    num_slices = (max(ip_data(:,slice_axis)) - min(ip_data(:,slice_axis)))/slice_width;
    num_slices = ceil(num_slices);
    % Info about non-slice dimensions are defined using bounding box
    poly_data = polyshape(unique(ip_data(:,axes_info),"rows"));
    [lim1,lim2] = boundingbox(poly_data);
    slice_axis_pts = ip_data(:,slice_axis);
    min_slice_axis_pts = min(slice_axis_pts);
    sample_result = []; % result of DP algorithm
    data_bin = zeros(size(ip_data,1),1); % binary result of DP algorithm
    ignored_pts = []; % points ignored due to projection
    bdry_pts = []; % boundary points for each slice
    for itr = 1 : num_slices
        %% extract individual slices
        % define boundaries of the current slice
        add_val = (itr - 1)*slice_width; % incremental value for the slices 
        lim3 = [min_slice_axis_pts + add_val, min_slice_axis_pts + add_val + slice_width];
        % extract data within the slice and project in non-slice plane
        cur_slice_bin = slice_axis_pts >= lim3(1) & slice_axis_pts < lim3(2);
        cur_slice_idx = find(cur_slice_bin); % index of all points in the slice
        cur_slice_pts_3d = ip_data(cur_slice_idx,:);
        % plotting 
        if itr == 1
%             figure
            ignored_pts = [];
%             plot3(ip_data(:,1),ip_data(:,2),ip_data(:,3),'k.')
        end
%         hold on
%         plot3(bdry_pts(:,1),bdry_pts(:,2),bdry_pts(:,3),'b*')
%         hold on
%         plot3(cur_slice_pts_3d(:,1),cur_slice_pts_3d(:,2),cur_slice_pts_3d(:,3),'b.')
        %% eliminate repeating points lost due to projection
        % add them to the result if the original point is held in the
        % simulation - considering it is critical to maintain the shape
        % find the unique points and add all other points to final result
        [~,filter_idx] = unique(cur_slice_pts_3d(:,axes_info),"rows");
        cur_slice_pts_filt_3d = cur_slice_pts_3d(filter_idx,:);
        if size(cur_slice_pts_filt_3d,1) ~= size(cur_slice_pts_3d,1)
            ignored_pts_struct = struct; % save the ignored points based on projection root
            % extract the ignored points
            bin_vec = zeros(size(cur_slice_pts_3d,1),1);
            bin_vec(filter_idx) = 1;
            del_pts = cur_slice_pts_3d(~bin_vec,:);
            for del_itr = 1 : size(cur_slice_pts_filt_3d,1)
                del_idx = ismember(del_pts(:,axes_info),...
                    cur_slice_pts_filt_3d(del_itr,axes_info),"rows");
                ignored_pts_struct(del_itr).data = del_pts(del_idx,:);
            end
        end
        pts_set1 = [lim1(1),lim3(1),lim2(1);lim1(2),lim3(2),lim2(1);lim1(2),lim3(1),lim2(1);lim1(2),lim3(2),lim2(1)];
        pts_set2 = [lim1(1),lim3(1),lim2(2);lim1(2),lim3(2),lim2(2);lim1(2),lim3(1),lim2(2);lim1(2),lim3(2),lim2(2)];
        bdry_pts = [bdry_pts;pts_set1;pts_set2];
        if size(cur_slice_pts_filt_3d,1) > 4 %(4 is an arbritary number here)
            result = DouglasPeucker(cur_slice_pts_filt_3d',epsilon,axes_info)';
        else
            result = cur_slice_pts_filt_3d;
        end
        % plot the result from DP
%         hold on
%         plot3(result(:,1),result(:,2),result(:,3),'r*')
        sample_result = [sample_result;result];
        if size(cur_slice_pts_filt_3d,1) ~= size(cur_slice_pts_3d,1)
            % update the filtered points to be added to the result 
            % add back projection lost points is root is in the result
            root_bin = ismember(cur_slice_pts_filt_3d,result,"rows");
            root_bin_idx = find(root_bin);
            for root_idx = 1 : size(root_bin_idx)
                ignored_pts = [ignored_pts;...
                    ignored_pts_struct(root_bin_idx(root_idx)).data];
            end
        end % end of ignored point addition block
    end % end of loop over number of slices 
    sample_result = [sample_result;ignored_pts];
    sample_result = RepeatRemove3D(sample_result);
    sample_idx_bin = ismember(ip_data,sample_result,"rows");
    data_bin(sample_idx_bin) = 1;
end