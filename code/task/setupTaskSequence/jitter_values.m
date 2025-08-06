function jittered_values = jitter_values(mean_value, upper_bound, lower_bound, ntrials)
%% function to create a random uniform distribution of values (e.g., seconds ITI)
% with a given mean value, upper and lower bound, for some number of
% trials.
%
% Micah Allen 2018


ms_a = mean_value-lower_bound;
ms_b = mean_value+upper_bound;


iti = linspace(ms_a,ms_b,ntrials);
jittered_values = iti(randperm(length(iti)));


end



