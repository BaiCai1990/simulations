%%
clear all;
std_dev = 0.025;

if std_dev == 0.025
    kernel = [0.1400 15.7300 68.26 15.7300 0.1400]; 
else
    n_obs = 10000;
    measures = normrnd(0, std_dev,n_obs);
    figure(1);
    h = histogram(measures, 'BinWidth', 0.01,  'Normalization', 'probability');
    bin_width = h.BinWidth;
    if(mod(int64(h.NumBins),int64(2)) == 0)
        h = histogram(measures, h.NumBins+1,  'Normalization', 'probability');
        bin_width = h.BinWidth;
    end
    kernel = h.Values;
end
L = size(kernel,2) * 8;
map(1:L,1:2) = 1e-3;
half_kernel = floor(size(kernel,2) / 2);
obstacle_pose = L/2;
obstacle_pose = 12;
for i=1:obstacle_pose
    k=1;
    for j=i-half_kernel:i+half_kernel
        if j > 0 && j <= L
            if i == obstacle_pose
                map(j,1) = map(j,1) + kernel(k);
            else
                map(j,2) = map(j,2) + kernel(k);
            end
        end
        k = k + 1;
    end
end
for i =1:L
    values(i) = map(i,1) ./ sum([map(i,1);map(i,2)]);
end

figure(2);
bar(values);
for i =1:L
    log_val(i) = log(map(i,1) ./ map(i,2));
    prob(i) = 1 - 1 / (1 + exp(log_val(i)))
end
figure;
bar(log_val);
figure;
bar(prob);