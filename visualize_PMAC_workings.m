%% Visualize PMAC workings
clear all;
close all;
occ_probs = [.7, .8, 0.75, 0.9, .45, .4, 0.85, .7, .65,.95, .8, 0.3, .2, .1, .15, .25, .9, .8,0.85, 0.9];
% Problem case: small error results in under estimating dynamics
%occ_probs = [.7, .8, 0.75, 0.9, .499, 0.501, 0.3, .2, .1, .15, .25];
num_of_plots = 8;
plot_xlim = length(occ_probs) + 1;
figure;
subplot(2,1,1),bar(occ_probs, 'BarWidth', 0.5); ylabel('p_{occupied}'); xlim([0 plot_xlim]);
set(gca,'ygrid','on')
consitent_index = 1;
for i=1:length(occ_probs)
    if(occ_probs(i) > 0.5)
        scores(i) = (occ_probs(i) - .5)*2;
        occ_scores(i) = (occ_probs(i) - .5)*2;
    else
        scores(i) = -(0.5 - occ_probs(i))*2;
        free_scores(i) = -(0.5 - occ_probs(i))*2;
    end
end
subplot(2,1,2),bar(occ_scores, 'BarWidth', 0.5); ylabel('state score'); xlim([0 plot_xlim]);
hold on;
bar(free_scores,'FaceColor', [0.850,  0.325,  0.098],'BarWidth', 0.5);
% add average
means = [mean(scores(1:4)) mean(scores(5:6)) mean(scores(7:11)) mean(scores(12:16)) mean(scores(17:end))];
for i=1:length(means)
    mean_values(1:2,i) = means(i);
end
mean_indexes = [[1,4]; [5,6]; [7,11]; [12,16]; [17,length(occ_probs)]]';
ax = plot(mean_indexes, mean_values,'Color', [0.466,  0.674,  0.188]); % 
legend(ax,'average score between state changes', 'location', 'SouthWest');
xlabel('Update index');
hold off;

entry = realmin('double'); exit = entry; 
free_count = exit; occupied_count = free_count;
last_exit_residue = 0; last_entry_residue = 0;
last_exit_cnt = 0; last_entry_cnt = 0;
prev_occ_prob = occ_probs(1);
for i=1:length(occ_probs)
    occ_prob = occ_probs(i);
    if(occ_prob > 0.5)
        occupied_prob = (occ_prob - 0.5) * 2;
        occupied_count = occupied_count + occupied_prob;
        % occ state
        if(prev_occ_prob < 0.5)
            last_exit_residue = 0;
            last_exit_cnt = 0;
            last_entry_residue = last_entry_residue / last_entry_cnt;
        end
        last_exit_cnt = last_exit_cnt + 1;
        % start counting the exit max up
        last_exit_residue = last_exit_residue + occupied_prob;
        
        % increment entry event
        if(last_entry_residue > 0.0)
            next_entry_cnt = min(occupied_prob,last_entry_residue);
            entry = entry + next_entry_cnt;
            last_entry_residue = last_entry_residue - next_entry_cnt;
        end
    else
        free_prob = (0.5 - occ_prob) * 2;
        free_count = free_count + free_prob;
        
        if(prev_occ_prob > 0.5)
            last_entry_residue = 0;
            last_entry_cnt = 0;
            last_exit_residue = last_exit_residue / last_exit_cnt;
        end
        last_entry_cnt = last_entry_cnt + 1;
        
        last_entry_residue = last_entry_residue + free_prob;
        
        if(last_exit_residue > 0.0)
            next_exit_cnt = min(free_prob,last_exit_residue);
            exit = exit + next_exit_cnt;
            last_exit_residue = last_exit_residue - next_exit_cnt;
        end
    end
    prev_occ_prob = occ_prob;
    occupied_counts(i) =  occupied_count;
    free_counts(i) =  free_count;
    exits(i) = exit;
    entries(i) = entry;
%     entry_res(i) = last_entry_residue;
%     exit_res(i) = last_exit_residue;
end
figure;
subplot(3,1,1), plot(free_counts); ylabel('free. sum'); hold on; plot(free_counts,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
subplot(3,1,2), plot(entries); ylabel('entry event sum'); hold on; plot(entries,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
subplot(3,1,3), plot(entries./free_counts); ylabel('\lambda_{entry}'); hold on; plot(entries./free_counts,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
xlabel('Update index');
figure;
subplot(3,1,1), plot(occupied_counts); ylabel('Occ. sum'); hold on; plot(occupied_counts,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
subplot(3,1,2), plot(exits); ylabel('exit event sum'); hold on; plot(exits,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
subplot(3,1,3), plot(exits./occupied_counts); ylabel('\lambda_{exit}'); hold on; plot(exits./occupied_counts,'r.','MarkerSize',10); hold off; xlim([0 plot_xlim]);
xlabel('Update index');
%% Show workings of algorithm
% figure;
% plot([entry_res', exit_res']);