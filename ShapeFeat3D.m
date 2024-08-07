%% Caluculate Eigen Values, NN region normal and Shannon Entropy 
function [nn_entropy,eigen_val,normal] = ShapeFeat3D(pts)
    nn_entropy = 4; % intialize a large value to account for all zero eigen values
    %disp("start eigen");
    cov_mat = cov(pts); % covariance matrix
    [eig_mat,eig_vals_temp] = eig(cov_mat); % eigen values & vectors calc.
    %disp("success");
%     % Debug
%     if size(eig_vals_temp,1) < 3
%         size(eig_vals_temp,1) 
%     end
    eig_vals = zeros(size(pts,2),1);
    for itr = 1 : size(pts,2)
        eig_vals(itr) = eig_vals_temp(itr,itr);
    end
    % eliminating cases of -ve zeros in eigen value calculations
    for itr = 1 : size(pts,2)
        if eig_vals(itr) < 0
            eig_vals(itr) = 0;
        end
    end
    % arrrange the eigen values in as/descending order
    if min(eig_vals) == max(eig_vals)
        min_eig_idx = 1;
        mid_eig_idx = 2;
        max_eig_idx = 3;
    else
        [~,min_eig_idx] = min(eig_vals);
        [~,max_eig_idx] = max(eig_vals);
        mid_eig_idx = setdiff([1,2,3],[min_eig_idx,max_eig_idx]);
    end
    min_eig = eig_vals(min_eig_idx);
    mid_eig = eig_vals(mid_eig_idx);
    max_eig = eig_vals(max_eig_idx);
    sum_eig = sum(eig_vals);  
%     % Linearity, Planrity Values
%     if max_eig > 0
%         shape_feat_vec(1) = (max_eig - mid_eig)/ max_eig;
%         shape_feat_vec(2) = (mid_eig - min_eig)/max_eig;
%         shape_feat_vec(3) = min_eig/max_eig;
%     else
%         shape_feat_vec = [0,0,0];
%     end  
    % shannon entropy calculation
    if sum_eig > 0 
        nn_entropy_temp = [];
        for itr = 1 : size(pts,2)
            e_value(itr) = eig_vals(itr)/sum_eig;
            if e_value(itr) == 0
                nn_entropy_temp(itr) = 0;
            else
                nn_entropy_temp(itr) = -e_value(itr)*log(e_value(itr));
            end
        end
        nn_entropy = sum(nn_entropy_temp);
    end
    if nn_entropy == 0
        nn_entropy = 4; % arbritrary value
    end
    eigen_val = [min_eig,mid_eig,max_eig];
    normal = eig_mat(:,min_eig_idx)/norm(eig_mat(:,min_eig_idx)); 
end % end of function definition