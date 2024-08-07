%% Assumed that the perfect data normal is along the Z axis
%% Calculate the normal with least RMS 
function optNormal = OptPCNormRMSE(ip_data,normal_vec,weight_vec,sum_weights)
    skp_ct = 0; % counter for number of "bad" NN regions
    pass_ct = 1;
    for itri = 1 : size(ip_data,1)
        % skip "bad" NN regions
        if sum(normal_vec(itri,:) == zeros(1,3)) == 3
            skp_ct = skp_ct + 1; 
            continue;
        end
        error_val = 0;
        sq_err = 0;
        for itrj = 1 : size(ip_data,1)
            cos_theta = max(min(dot(normal_vec(itri,:),normal_vec(itrj,:))/(norm(normal_vec(itri,:))*norm(normal_vec(itrj,:))),1),-1);
            temp_theta = real(acosd(cos_theta));
            error_val = error_val + temp_theta;
            sq_err = sq_err + (weight_vec(itrj)/sum_weights)*(temp_theta^2);
        end
        tempRSME = sqrt(sq_err);
        if pass_ct == 1
            minRMSE_val = tempRSME;
            optIdx = itri;
        else
            if tempRSME < minRMSE_val
                minRMSE_val = tempRSME;
                optIdx = itri;
            end
        end
        pass_ct = pass_ct + 1;
    end
    optNormal = normal_vec(optIdx,:);
end