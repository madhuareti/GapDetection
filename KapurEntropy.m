%% Calucalte the Kapurs entropy for a pre-defined segmentation
function entropy = KapurEntropy(data,data_prob,th_vec_comp)
    entropy = 0;
    for itr = 2 : size(th_vec_comp,2)
        data_prob_temp_bin = data >= th_vec_comp(itr-1) & data < th_vec_comp(itr); 
        data_prob_temp = data_prob(data_prob_temp_bin);
        data_temp_sum = sum(data_prob_temp);
        if data_temp_sum == 0 % avoiding NaN 
            data_temp_sum = 1e-8;
        end
        entropy_temp = 0;
%         entropy_temp_vec = [];
        % calculate entropy for each segment
        for itr2 = 1 : size(data_prob_temp,1)
            if data_prob_temp(itr2) > 0
                % calc distrubution of probability distribution
                temp_val = data_prob_temp(itr2)/data_temp_sum;
            else
                continue;
            end
            entr_temp = temp_val*log(temp_val);
            entropy_temp = entropy_temp - entr_temp;
        end
        % combined entropy of all segments
        entropy = entropy + entropy_temp;
    end
end