%% Calculate optimal numof bins based on Freedman-Diaconis rule
function num_bins = OptimalBinHist(data)
    data_median = median(data);
    data_h1 = data(data <= data_median);
    data_h2 = data(data > data_median);
    data_q1 = median(data_h1);
    data_q3 = median(data_h2);
    iqr_data = data_q3 - data_q1;
    num_data = size(data,1);
%     % debug
%     if size(data,2) < size(data,1)
%         size(data)
%     end
%     % debug end
    % Freedman-Diaconis 1981
    % converting bin width to number
     bin_width = (2*iqr_data)/nthroot(num_data,3);
     num_bins = round((max(data) - min(data))/bin_width);
    if num_bins == 0 || (num_bins > size(data,1)) || isnan(num_bins)
        num_bins = 1;
    end
%     % figure
%     opHistObj = histogram(data,num_bins,'Normalization',var);
end

