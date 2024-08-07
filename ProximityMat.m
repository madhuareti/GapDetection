% pairwise distance between two multi point inputs
% each row deals with one point in ip1
function prox_mat = ProximityMat(ip_data1,ip_data2)
    prox_mat = zeros(size(ip_data1,1), size(ip_data2,1));
    for itr = 1 : size(ip_data1,1)
        prox_mat(itr,:) = sqrt(sum((ip_data1(itr,:) - ip_data2)'.^2));
    end
end