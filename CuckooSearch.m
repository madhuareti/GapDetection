% -----------------------------------------------------------------
% Cuckoo Search (CS) algorithm by Xin-She Yang and Suash Deb      %
% Programmed by Xin-She Yang at Cambridge University              %
% Programming dates: Nov 2008 to June 2009                        %
% Last revised: Dec  2009   (simplified version for demo only)    %
% Last revised: Aug  2020 by Madhu Areti    %
% -----------------------------------------------------------------
% Papers -- Citation Details:
% 1) X.-S. Yang, S. Deb, Cuckoo search via Levy flights,
% in: Proc. of World Congress on Nature & Biologically Inspired
% Computing (NaBIC 2009), December 2009, India,
% IEEE Publications, USA,  pp. 210-214 (2009).
% http://arxiv.org/PS_cache/arxiv/pdf/1003/1003.1594v1.pdf 
% 2) X.-S. Yang, S. Deb, Engineering optimization by cuckoo search,
% Int. J. Mathematical Modelling and Numerical Optimisation, 
% Vol. 1, No. 4, 330-343 (2010). 
% http://arxiv.org/PS_cache/arxiv/pdf/1005/1005.2908v2.pdf
% ----------------------------------------------------------------%
% This demo program only implements a standard version of         %
% Cuckoo Search (CS), as the Levy flights and generation of       %
% new solutions may use slightly different methods.               %
% The pseudo code was given sequentially (select a cuckoo etc),   %
% but the implementation here uses Matlab's vector capability,    %
% which results in neater/better codes and shorter running time.  % 
% This implementation is different and more efficient than the    %
% the demo code provided in the book by 
%    "Yang X. S., Nature-Inspired Metaheuristic Algoirthms,       % 
%     2nd Edition, Luniver Press, (2010).                 "       %
% --------------------------------------------------------------- %

% =============================================================== %
% Notes:                                                          %
% Different implementations may lead to slightly different        %
% behavour and/or results, but there is nothing wrong with it,    %
% as this is the nature of random walks and all metaheuristics.   %
% -----------------------------------------------------------------
function [best_nest,max_entropy,tot_time,num_iter] = CuckooSearch(sv_val_vec,num_sol,num_thresh,max_iter,max_rep)
    rng default;
    tic;
    ip_range = max(sv_val_vec) - min(sv_val_vec);
    pa = 0.25; % Discovery rate of alien eggs/solutions (Recommended value in Literature::MA)
    %% Simple bounds of the search domain
    % Edited to suit image thresholding: MA
    num_bins = OptimalBinHist(sv_val_vec);
    [prob_vec_temp,sv_bin_edges_temp] = histcounts(sv_val_vec,num_bins,'Normalization', 'probability');
%     [prob_vec,sv_bin_edges_temp] = histcounts(sv_val_vec,'Normalization', 'probability');
%     num_bins = size(prob_vec,2);
    %%%%%%%%%% Approximation of SV values to reduce the size of the design
    %%%%%%%%%% space
    % include minimum and max elements in addition to the mid values
    sv_bin_mid_ex = zeros(size(sv_bin_edges_temp,2) - 1, 1);
    sv_bin_mid_ex(1,1) = sv_bin_edges_temp(1);
    for itr = 1 : size(sv_bin_edges_temp,2) - 1
        sv_bin_mid_ex(itr+1,1) = (sv_bin_edges_temp(itr+1) - sv_bin_edges_temp(itr))/2 + sv_bin_edges_temp(itr);
    end
    sv_bin_mid_ex(size(sv_bin_edges_temp,2)+1,1) = sv_bin_edges_temp(size(sv_bin_edges_temp,2));
    prob_vec_temp = prob_vec_temp';
    prob_vec(1,1) = sum(sv_val_vec == sv_bin_edges_temp(1))/size(sv_val_vec,1);
    prob_vec(2,1) = sum(sv_val_vec > sv_bin_edges_temp(1) & sv_val_vec <= sv_bin_edges_temp(2))/size(sv_val_vec,1);
    prob_vec(3:size(prob_vec_temp,1) + 1) = prob_vec_temp(2:end)';
    prob_vec(size(prob_vec,1) +1 ,1) = sum(sv_val_vec > sv_bin_edges_temp(end-1) & sv_val_vec <= sv_bin_edges_temp(end))/size(sv_val_vec,1);
    % Lower bound
    Lb = sv_bin_edges_temp(1)*ones(1,num_thresh); % lower edge limit of the histogram
    % Upper bound
    Ub = sv_bin_edges_temp(size(sv_bin_edges_temp,2))*ones(1,num_thresh); % upper edge limit of the histogram
    clear histObj;
    clear num_bins;
    % Random initial solutions for the optimizer
    nest_vec = zeros(num_sol,num_thresh);
    for itr = 1 : num_sol
        nest_vec(itr,:) = Lb + (Ub-Lb).*rand(size(Lb));
        nest_vec(itr,:) = sort(nest_vec(itr,:));
    end
    nest_vec = sortrows(nest_vec,1);
    % Best Solution of the intial values
    fit_vec = 2.*ones(num_sol,1);
    [fmin,best_nest,nest_vec,fit_vec] = getBestNest(sv_bin_mid_ex,prob_vec,nest_vec,nest_vec,fit_vec);
    % fmin is the minimum best fitness value expected by the algorithm
    num_iter = 0;
    num_rep = 0;
    % Stopping criteria:: Number of iter. & continous times best fitness don't change
    %% Iterations Solution
    while(num_iter <= max_iter && num_rep <= max_rep)
        new_nest_vec = getCuckoos(nest_vec,best_nest,Lb,Ub,ip_range); % Generate new solutions (but keep the current best)
        [~,~,nest_vec,fit_vec] = getBestNest(sv_bin_mid_ex,prob_vec,nest_vec,new_nest_vec,fit_vec);
        num_iter = num_iter+1; % Update the counter
        % Randomized Solution removal - cuckoo egg discovered scenario
        new_nest_vec = emptyNests(nest_vec,Lb,Ub,pa) ;
%         % Debug
%         if sum(double(new_nest_vec == nest_vec)) == size(nest_vec,1)
%             nest_vec; 
%         end
%         % Debug End
        % Evaluate this set of solutions
        [fnew,best_nest_cur,nest_vec,fit_vec] = getBestNest(sv_bin_mid_ex,prob_vec,nest_vec,new_nest_vec,fit_vec);
        % Update global fitness minimum and reset repetition counter
        if fnew < fmin
            fmin = fnew;
            best_nest = best_nest_cur;
            num_rep = 0;
        else
            if fnew == fmin
                if sum(best_nest == best_nest_cur) == size(best_nest_cur,2)
                    num_rep = num_rep + 1;
                end
                % update the threshold values to potentially increase the
                % range
                for itr = 1 : size(best_nest,2)
                    if itr <= floor(size(best_nest,2) / 2)
                        best_nest(itr) = max(best_nest(itr),best_nest_cur(itr));
                    else
                        best_nest(itr) = min(best_nest(itr),best_nest_cur(itr));
                    end
                end
                clear itr;
            else
                num_rep = 0;
            end
        end
    end %% End of iterative solution
%% Display the nests
max_entropy = 1/fmin;
tot_time = toc;
% disp(strcat('Total number of iterations = ',num2str(num_iter-1)));
% disp(strcat('Max. Ip. Val. = ',num2str(max(ip_data))));
% disp(strcat('Min. Ip. Val. = ',num2str(min(ip_data))));
% disp(strcat('Threshold Values = ',num2str(best_nest)));
% disp(strcat('Time taken for analysis = ',num2str(tot_time)));
% disp(strcat('Max. Entropy = ',num2str(max_entropy)));
% end of the main function
%% --------------- All subfunctions are list below ------------------
% Get cuckoos(candidate threshold values) by random walk
% respondible for the aggressive jumps in the Levy walk style
function nest_vec = getCuckoos(nest_vec,best_nest,Lb,Ub,ip_range)
    % Levy flights
    num_sol = size(nest_vec,1);
    % Levy exponent and coefficient
    % For details, see equation (2.21), Page 16 (chapter 2) of the book
    % X. S. Yang, Nature-Inspired Metaheuristic Algorithms, 2nd Edition, Luniver Press, (2010).
    beta = 3/2; % Recommended in literature
    sigma = (gamma(1+beta)*sin(pi*beta/2)/(gamma((1+beta)/2)*beta*2^((beta-1)/2)))^(1/beta);
    for itr = 1 : num_sol
        cur_nest = nest_vec(itr,:);
        % Levy flights by Mantegna's algorithm
        u = randn(size(cur_nest)) * sigma;
        v = randn(size(cur_nest));
        step = u./(abs(v).^(1/beta));
        % In the next equation, the difference factor (s-best) means that 
        % when the solution is the best solution, it remains unchanged.     
        stepsize = 0.01 *step .*(cur_nest - best_nest);
        % Here the factor 0.01 comes from the fact that L/100 should the typical
        % step size of walks/flights where L is the typical lenghtscale; 
        % otherwise, Levy flights may become too aggresive/efficient, 
        % which makes new solutions (even) jump out side of the design domain 
        % (and thus wasting evaluations).
        % Now the actual random walks or flights
        % MA Edit: Making the Levy Flight random & aggressive to support max. search space exploration
        temp_rand_vec = randi([0 1], size(stepsize)); % random binary vector
        multiplier = 6;
        stepsize = multiplier * stepsize .* temp_rand_vec; % making the jumps aggressive
        temp_step_vec = stepsize .*randn(size(cur_nest)); 
        cur_nest = cur_nest + temp_step_vec;
        % change the new nests impacted by the tail of normal distribution
        % minus the aggressive multiplier
        for idx_itr = 1 : size(cur_nest,1)
            if (abs(min(cur_nest(idx_itr,:)) - Lb(idx_itr)) < ip_range*0.1) || (abs(max(cur_nest(idx_itr,:)) - Ub(idx_itr)) < ip_range*0.1)
                if temp_rand_vec(idx_itr) 
                    temp_step_vec(idx_itr,:) = temp_step_vec(idx_itr,:)./multiplier;
                    cur_nest(idx_itr,:) = nest_vec(itr,:) + temp_step_vec(idx_itr,:);
                end
            end
            cur_nest(idx_itr,:) = sort(cur_nest(idx_itr,:));
        end
        clear temp_rand_vec;
        clear temp_step_vec;
        % Apply simple bounds/limits
        nest_vec(itr,:) = simpleBounds(cur_nest,Lb,Ub);
    end
% end of function
%% Find the current best nest and update the previously identified nests
% maximizing information entropy between the segments
% ip data == the SV value from the histogram mid values
function [fmin,best_nest,nest_vec,fit_vec_upd] = getBestNest(ip_data,ip_data_prob,nest_vec,newnest_vec,fit_vec)
    % Evaluating all new solutions
    fit_vec_upd = fit_vec;
    for itr = 1 : size(nest_vec,1)
        % range to determine the values between the bounds
        % adjust the max value to adjust for "<" in kapurs entropy calc
        th_vec = [min(ip_data), newnest_vec(itr,:), max(ip_data)+0.1]; 
        fnew_temp = KapurEntropy(ip_data,ip_data_prob,th_vec);
        if isnan(fnew_temp)
            continue;
        end
        % obj value is inversed to maintain the Minimization nature of CS and Maximization of Entropy
        fnew = 1 / fnew_temp; 
        if fnew <= fit_vec(itr)
           fit_vec_upd(itr) = fnew;
           nest_vec(itr,:) = newnest_vec(itr,:);
        end
    end
    % Find the current best
    [fmin,fmin_idx] = min(fit_vec_upd);
    best_nest = nest_vec(fmin_idx,:);
    best_nest = sort(best_nest);
% end of function
%% Replace some nests by constructing new solutions/nests
% Responsible for the local exploration after a jump
function new_nest_vec = emptyNests(nest_vec,Lb,Ub,pa)
    % A fraction of worse nests are discovered with a probability pa
    num_sol = size(nest_vec,1);
    % Discovered or not -- a status vector
    K = rand(size(nest_vec)) > pa;
    % In the real world, if a cuckoo's egg is very similar to a host's eggs, then 
    % this cuckoo's egg is less likely to be discovered, thus the fitness should 
    % be related to the difference in solutions.  Therefore, it is a good idea 
    % to do a random walk in a biased way with some random step sizes.  
    % New solution by biased/selective random walks
    stepsize = rand *(nest_vec(randperm(num_sol),:)-nest_vec(randperm(num_sol),:));
    new_nest_vec = nest_vec + stepsize.*K;
    for itr = 1 : size(new_nest_vec,1)
        cur_nest = sort(new_nest_vec(itr,:));
        new_nest_vec(itr,:) = simpleBounds(cur_nest,Lb,Ub);  
    end
% end of function
%% Application of simple boundary constraints
function bounded_op = simpleBounds(unbounded_ip,Lb,Ub)
  % Apply the lower bound
  ns_tmp = unbounded_ip;
  bin_vec = ns_tmp < Lb;
  ns_tmp(bin_vec) = Lb(bin_vec);
  % Apply the upper bounds 
  bin_vec = ns_tmp > Ub;
  ns_tmp(bin_vec) = Ub(bin_vec);
  % Update this new move 
  bounded_op = ns_tmp;
% end of function