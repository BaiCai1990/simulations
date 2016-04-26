%%
clear all;
import Hmm_EM_cell
import Imc_cell
import Pmac_cell
import Probabilistic_cell
L = 10; % Map size
map(1:L) = 0;
robot = 1;
rng('shuffle');
% Sensor
range = 9;
variance = 1.0; % in grid cells

% Robot step size
robotStepSize = 0;

% Obstacles
obstacle1 = [6,0.4,0.7]; % pos,free->occ, occ->free,
obstacle2 = [2,0.45,0.5];

obstacles = [obstacle1;];% obstacle2];

% init learning models
p_measurement = 0.191*2;
%p_measurement = 0.68;
hmm_grid(1:L) = Hmm_EM_cell([0.5 0.5], 1e-2, p_measurement);
imac_grid(1:L) = Imc_cell();
pmac_grid(1:L) = Pmac_cell(p_measurement,(1-p_measurement));
filter_grid(1:L) = Probabilistic_cell();
markov_time = 60;
N = markov_time*1000;
%N=300;
% store data for visualization of learning progress

a_data_hmm(1:N/markov_time,1:Hmm_EM_cell.N,1:Hmm_EM_cell.N) = -1;
a_data_imac(1:N/markov_time,1:2,1:2) = -1;
a_data_pmac(1:N/markov_time,1:2,1:2) = -1;
%q_data(1:N,1:Hmm_EM_cell.N) = -1;
obstacle_number_to_evaluate = 1;
occupied_count(1:L) = 0;
free_count = occupied_count;
times = 1:N;

observations(N/markov_time+1) = 0;
obstacle_apearent = observations;
learner_update_count = 0;
%%
% simulation of robot movements
for t= times
    if(mod(t,N/10) == 0)
        t/N*100
    end
    % Take measurement
    correct_dist = range + robot;
    for z=1:range;
        index = z+robot;
        if(map(index)==1)
            correct_dist = index;
        end
    end
    measured_dist = round(normrnd(correct_dist,variance));
    scanResult(1:L) = -1; % -1 = Unseen, 0 = Free, 1 = Occupied
    if measured_dist > robot + range
        scanResult(robot+1:robot + range) = 0;
    else
        scanResult(robot+1:measured_dist-1) = 0;
        scanResult(measured_dist) = 1;
    end
    % Add measurement to filter
    for cell_no=1:size(scanResult,2)
        if cell_no == obstacles(1,1)
            if scanResult(cell_no) ~= -1
                filter_grid(cell_no).update(scanResult(cell_no));
            end
        end
    end
    
    if(mod(t,markov_time) == 0)
%         filter_val(1:length(filter_grid)) = 0;
%         for i=1:length(filter_grid)
%             filter_val(i) = filter_grid(i).getOccupancy_prob();
%         end    
%         figure(1),bar(filter_val);
        learner_update_count = learner_update_count + 1;
        % Put filtered data into method
        for cell_no=1:size(scanResult,2)
            if cell_no == obstacles(1,1)                
                occ_prob = filter_grid(cell_no).getOccupancy_prob();
                if scanResult(cell_no) ~= 0.5
                    if(occ_prob > 0.5)
                        imac_grid(cell_no).update(1);
                    else
                        imac_grid(cell_no).update(0);
                    end
                    pmac_grid(cell_no).update(occ_prob);
                    observations(learner_update_count) = occ_prob;
                    obstacle_apearent(learner_update_count) = map(obstacles(1,1));
                    %                     if(scanResult(cell_no) == 1)
                    %                         occupied_count(cell_no) = occupied_count(cell_no) + 1;
                    %                     else
                    %                         free_count(cell_no) = free_count(cell_no) + 1;
                    %                     end
                end
            end
        end
        
        % Update obstacles
        for i=1:size(obstacles,1)
            if(obstacles(i,1) ~= robot)
                % Sample Bernoulli random variable
                rn = rand(1);
                if( rn <= obstacles(i,map(obstacles(i,1))+2) )
                    map(obstacles(i,1)) = xor(map(obstacles(i,1)),1);
                end
            end
        end
        
        %hmm_grid(obstacles(obstacle_number_to_evaluate,1)).a
        %     a_data_hmm(t,:,:) = hmm_grid(obstacles(obstacle_number_to_evaluate,1)).a;
        a_data_pmac(learner_update_count,:,:) = pmac_grid(obstacles(obstacle_number_to_evaluate,1)).getTransitionMatrix();
        a_data_imac(learner_update_count,:,:) = imac_grid(obstacles(obstacle_number_to_evaluate,1)).getTransitionMatrix();
        %q_data(t,:) = hmm_grid(obstacles(obstacle_number_to_evaluate,1)).q;
    end
    
    
end

%% Display learning results
update_indexes = 1:length(a_data_imac);
close all;
plot_resolution = 1;
f = figure('name','State transition probabilities HMM');
movegui(f,'northwest');
% p1 = plot(times(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end),...
%     a_data_hmm(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end,1,2));%title('a(1,2) occupied -> free ')
% hold on;
% p2 = plot([times(Hmm_EM_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,3) obstacles(obstacle_number_to_evaluate,3)]);

p3 = plot(update_indexes(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_imac(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end,1,2));%title('a(1,2) occupied -> free')
%hold on;
hold on;
plot(update_indexes(Pmac_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_pmac(Pmac_cell.no_of_initial_statistics_updates:plot_resolution:end,1,2));title('a(1,2) occupied -> free')
%
plot([update_indexes(Pmac_cell.no_of_initial_statistics_updates) update_indexes(end)], [obstacles(obstacle_number_to_evaluate,3) obstacles(obstacle_number_to_evaluate,3)]);
ylim([0 1]);
xlabel('Used observations');
ylabel('P_{exit}');
% legend([p2 p3 p1],['Static prob.';'        IMAC';'  HMM-online';], 'location', 'southoutside');
figure;
% p1 = plot(times(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end),...
%     a_data_hmm(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end,2,1));%title('a(2,1) free -> occupied')
% hold on;
% p2 = plot([times(Hmm_EM_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,2) obstacles(obstacle_number_to_evaluate,2)]);
p3 = plot(update_indexes(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_imac(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end,2,1));%title('a(2,1) free -> occupied')
hold on;
plot(update_indexes(Pmac_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_pmac(Pmac_cell.no_of_initial_statistics_updates:plot_resolution:end,2,1));title('a(2,1) free -> occupied')
plot([update_indexes(Pmac_cell.no_of_initial_statistics_updates) update_indexes(end)], [obstacles(obstacle_number_to_evaluate,2) obstacles(obstacle_number_to_evaluate,2)]);
ylim([0 1]);
xlabel('Used observations');
ylabel('P_{entry}');
figure, plot(observations);
figure,plot(abs(observations-obstacle_apearent))
% legend([p2 p3 p1],['Static prob.';'        IMAC';'  HMM-online'], 'location', 'southoutside');
