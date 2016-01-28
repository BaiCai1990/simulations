function [ divergence ] = kullbackDivergence( benchmark_prob, prob )
%UNTITLED Quatifies the difference between probabilities
%   Calculates the Kullback-Leibler divergence between probabilites
%   See page 3486 in Patch map: A benchmark for occupancy grid Algorithm
%   evaluation
epsilon = 1e-6;
N = size(benchmark_prob,1) * size(benchmark_prob,2); % no of grid cells
D_kl(1:N) = 0;
k = 1;
for i = 1:size(benchmark_prob,1)
    for j = 1:size(benchmark_prob,2)
        if benchmark_prob(i,j) > epsilon && prob(i,j) > epsilon
            D_kl(k) = benchmark_prob(i,j) * log(benchmark_prob(i,j) / prob(i,j));
        elseif ((1-benchmark_prob(i,j)) > epsilon) && ((1-prob(i,j)) > epsilon)
            D_kl(k) = D_kl(k) + (1-benchmark_prob(i,j)) * log((1-benchmark_prob(i,j)) / (1-prob(i,j)));
        end % else keep zero, should never happen
        k = k + 1;
    end
end
divergence = sum(D_kl);
end

