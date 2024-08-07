%% Calculate the optimal principal component vector based on least RMS on all NNs 
function opt_pca_vec = OptPCAVecRMSE(ip_data,ip_pca_vec,weight_vec,sum_weights)
    skp_ct = 0; % counter for number of "bad" NN regions
    pass_ct = 1;
    for itri = 1 : size(ip_data,1)
        % skip "bad" NN regions
        if sum(ip_pca_vec(itri,:) == zeros(1,3)) == 3
            skp_ct = skp_ct + 1; 
            continue;
        end
        error_val = 0;
        sq_err = 0;
        for itrj = 1 : size(ip_data,1)
            cos_theta = max(min(dot(ip_pca_vec(itri,:),ip_pca_vec(itrj,:))/(norm(ip_pca_vec(itri,:))*norm(ip_pca_vec(itrj,:))),1),-1);
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
    opt_pca_vec = ip_pca_vec(optIdx,:);
end