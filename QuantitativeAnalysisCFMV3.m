function [AlgoRecall,AlgoPrecision,AlgoF1Score,AlgoAccuracy,AlgoMCC,TP_num,FP_num,TN_num,FN_num] = QuantitativeAnalysisCFMV3(damaged_points,undamaged_points,gt_damaged_points)    
    %% Calculation of Recall and Precision of the said Algorithm
    % Result Analysis
    TP_num = 0;
    FN_num = 0;
    FP_num = 0;
    TN_num = 0;
    for itr = 1 : size(damaged_points,1)
        bin_val = ismember(gt_damaged_points,damaged_points(itr,:),'rows');
        if sum(bin_val) > 0
            TP_num = TP_num + 1;
        else
            FP_num = FP_num + 1;
        end
        clear idx;
        clear d;
    end  
    for itr = 1 : size(undamaged_points,1)
        bin_val = ismember(gt_damaged_points,undamaged_points(itr,:),'rows');
        if sum(bin_val) > 0
            FN_num = FN_num + 1;
        else
            TN_num = TN_num + 1;
        end
    end
    % Recall
    if TP_num + FN_num == 0
        AlgoRecall = 0;
    else
        AlgoRecall = TP_num/(TP_num + FN_num);
    end
    % Precision
    if TP_num + FP_num == 0
        AlgoPrecision = 0;
    else
        AlgoPrecision = TP_num/(TP_num + FP_num);
    end
    AlgoF1Score = harmmean([AlgoRecall,AlgoPrecision]);
    AlgoAccuracy = (TP_num + TN_num)/(TP_num + FN_num + FP_num + TN_num);
    % Kappa 
    pe_num_temp1 = (TP_num + FP_num);
    pe_num_temp2 = (TP_num + FN_num);
    pe_num_temp3 = (FN_num + TN_num);
    pe_num_temp4 = (TN_num + FP_num);
    pe_num_den = (size(undamaged_points,1) + size(damaged_points,1))^2;
    pe_val = (pe_num_temp1*pe_num_temp2*pe_num_temp3*pe_num_temp4)/pe_num_den;
    AlgoKappa = (AlgoAccuracy - pe_val)/(1 - pe_val);
    % MCC
    AlgoMCC_nume = TP_num*TN_num - FP_num*FN_num;
    AlgoMCC_den1 = (TP_num + FP_num);
    AlgoMCC_den2 = (TP_num + FN_num);
    AlgoMCC_den3 = (TN_num + FP_num);
    AlgoMCC_den4 = (TN_num + FN_num);
    if AlgoMCC_den1 == 0
        AlgoMCC_den1 = 1;
    end
    if AlgoMCC_den2 == 0
        AlgoMCC_den2 = 1;
    end
    if AlgoMCC_den3 == 0
        AlgoMCC_den3 = 1;
    end
    if AlgoMCC_den4 == 0
        AlgoMCC_den4 = 1;
    end
    AlgoMCC_deno = sqrt(AlgoMCC_den1 * AlgoMCC_den2 * AlgoMCC_den3 * AlgoMCC_den4);
    AlgoMCC = AlgoMCC_nume / AlgoMCC_deno;
end