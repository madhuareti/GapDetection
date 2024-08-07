% output the probabilty value and SV values
% 1 - 6 freq and SV value pairs
% abs max, median, last bin and 4 different multiplication factors
% 7 - 10 freq values about a defined SV value
function high_freq_val_vec = SVFreqAnal(ip_data)
    % testing different values of the multiplier (c) for STP-I
    stop_cond_mul_fac1 = 0.7; 
    stop_cond_mul_fac2 = 0.8; 
    stop_cond_mul_fac3 = 0.9; 
    stop_cond_mul_fac4 = 1; 
    % 0.33/2 value is mid point in SV range
    stop_cond1 = (0.33/2)*stop_cond_mul_fac1;
    stop_cond2 = (0.33/2)*stop_cond_mul_fac2;
    stop_cond3 = (0.33/2)*stop_cond_mul_fac3;
    stop_cond4 = (0.33/2)*stop_cond_mul_fac4;
    high_freq_val_vec = [];
    num_bins = OptimalBinHist(ip_data);
    [prob_vec,edges] = histcounts(ip_data,num_bins,'Normalization', 'probability');
    hist_mid_pt = zeros(size(edges,2),1);
    for itr = 2 : size(edges,2)
        hist_mid_pt(itr - 1) = edges(itr - 1) + (edges(itr) - edges(itr - 1))/2;
    end
    % multipliers 1-4
    % freq value sum after the multiplier SV
    high_freq_val_vec = zeros(4,1);
    if sum(hist_mid_pt >= stop_cond1)
        temp_idx_val_0165_1 = num_bins - sum(hist_mid_pt >= stop_cond1) + 1;
        high_freq_val_vec(1) = sum(prob_vec(temp_idx_val_0165_1 : num_bins));
    end
    if sum(hist_mid_pt >= stop_cond2)
        temp_idx_val_0165_2 = num_bins - sum(hist_mid_pt >= stop_cond2) + 1;
        high_freq_val_vec(2) = sum(prob_vec(temp_idx_val_0165_2 : num_bins));
    end
    if sum(hist_mid_pt >= stop_cond3)
        temp_idx_val_0165_3 = num_bins - sum(hist_mid_pt >= stop_cond3) + 1;
        high_freq_val_vec(3) = sum(prob_vec(temp_idx_val_0165_3 : num_bins));
    end
    if sum(hist_mid_pt >= stop_cond4)
        temp_idx_val_0165_4 = num_bins - sum(hist_mid_pt >= stop_cond4) + 1;
        high_freq_val_vec(4) = sum(prob_vec(temp_idx_val_0165_4 : num_bins));
    end
end