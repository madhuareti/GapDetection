% given an plane equation ax+by+cz=d, project points xyz onto the plane
% return the coordinates of the new projected points
% written by Neo Jing Ci, 11/7/18
% modified by Madhu Areti, 11.01.23
function proj_data = Proj32D(ip_data,plane_pt,plane_normal,keep_idx)
    a = plane_normal(1);
    b = plane_normal(2);
    c = plane_normal(3);
    d = plane_pt*plane_normal';
    A = [1 0 0 -a; 0 1 0 -b; 0 0 1 -c; a b c 0];
    for itr = 1 : size(ip_data,1)
        B = [ip_data(itr,1); ip_data(itr,2); ip_data(itr,3); d];
        proj_data(itr,:) = (A\B)';
    end
    proj_data = proj_data(:,1:3); % 3D projections
    % remove repeating points
    for itr = 1 : size(proj_data,1)
        proj_data_bin = ismember(proj_data,proj_data(itr,:),'rows');
        if sum(proj_data_bin) > 1
            proj_data = [];
            itr = itr-1;
        end
    end
    proj_data = proj_data(:,keep_idx); % remove the plane data itself
    % remove repeating points
    for itr = 1 : size(proj_data,1)
        proj_data_bin = ismember(proj_data,proj_data(itr,:),'rows');
        if sum(proj_data_bin) > 1
            proj_data = [];
            itr = itr-1;
        end
    end
end
