%%
clear all;
import Hmm_EM_cell
import Imc_cell
L = 10; % Map size
map(1:L) = 0;
robot = 1;

% Sensor
range = 9;
variance = 0.5; % in grid cells

% Robot step size
robotStepSize = 0;

% Obstacles
obstacle1 = [6,0.9,0.2]; % pos, free->occ, occ->free
obstacle2 = [2,0.45,0.5];

obstacles = [obstacle1;];% obstacle2];

% init learning models
for cell_no=1:L
    hmm_grid(cell_no) = Hmm_EM_cell([0.5 0.5], 5e-4, 0.68);
end

for cell_no=1:L
    imac_grid(cell_no) = Imc_cell();
end

N = 5e4;

% store data for visualization of learning progress
a_data_hmm(1:N,1:Hmm_EM_cell.N,1:Hmm_EM_cell.N) = -1;
a_data_imac(1:N,1:2,1:2) = -1;
q_data(1:N,1:Hmm_EM_cell.N) = -1;
obstacle_number_to_evaluate = 1;
occupied_count(1:L) = 0;
times = 1:N;
%%
% simulation of robot movements
for t= times
    % Update obstacles
    for i=1:size(obstacles,1)
        if(obstacles(i,1) ~= robot)
            % Sample Bernoulli random variable
            rn = rand(1);
            if(rn <= obstacles(i,map(obstacles(i,1))+2))
                map(obstacles(i,1)) = xor(map(obstacles(i,1)),1);
            end
        end
    end
    % count no. of occ. and free to use for groud truth
    %     for i=1:L
    %         occupied_count(i) = occupied_count(i) + map(i);
    %     end
    
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
    
    % Move bot
    %     for step=1:robotStepSize
    %         %nextRobotPos = mod(robot+step,L+1);
    %         nextRobotPos = robot + 1;
    %         if nextRobotPos > L
    %             nextRobotPos = 1;
    %         end
    %         % Check for obstacles
    %         if(map(nextRobotPos) ~= 1 )
    %             robot = nextRobotPos;
    %         else
    %             break;
    %         end
    %     end
    
    % Put scan into method
    for cell_no=1:size(scanResult,2)
        if cell_no == obstacles(1,1)
            hmm_grid(cell_no).update(scanResult(cell_no));
            if scanResult(cell_no) ~= -1
                imac_grid(cell_no).update(scanResult(cell_no));
            else
                imac_grid(cell_no).updateProject();
            end
        end
    end
    %hmm_grid(obstacles(obstacle_number_to_evaluate,1)).a
    a_data_hmm(t,:,:) = hmm_grid(obstacles(obstacle_number_to_evaluate,1)).a;
    a_data_imac(t,:,:) = imac_grid(obstacles(obstacle_number_to_evaluate,1)).getTransitionMatrix();
    q_data(t,:) = hmm_grid(obstacles(obstacle_number_to_evaluate,1)).q;
end

%% Display learning results
close all;
plot_resolution = 1;
f = figure('name','State transition probabilities HMM');
movegui(f,'northwest');
subplot(1,2,1),
plot(times(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_hmm(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end,1,2));title('a(1,2) occupied -> free ')
hold on;
plot([times(Hmm_EM_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,3) obstacles(obstacle_number_to_evaluate,3)]);
hold off;
ylim([0 1]);

subplot(1,2,2),
plot(times(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_hmm(Hmm_EM_cell.no_of_initial_statistics_updates:plot_resolution:end,2,1));title('a(2,1) free -> occupied')
hold on;
plot([times(Hmm_EM_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,2) obstacles(obstacle_number_to_evaluate,2)]);
hold off;
ylim([0 1]);

f = figure('name','State transition probabilities IMAC');
movegui(f,'southwest');
subplot(1,2,1),
plot(times(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_imac(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end,1,2));title('a(1,2) occupied -> free')
hold on;
plot([times(Imc_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,3) obstacles(obstacle_number_to_evaluate,3)]);
hold off;
ylim([0 1]);

subplot(1,2,2),
plot(times(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end),...
    a_data_imac(Imc_cell.no_of_initial_statistics_updates:plot_resolution:end,2,1));title('a(2,1) free -> occupied')
hold on;
plot([times(Imc_cell.no_of_initial_statistics_updates) times(end)], [obstacles(obstacle_number_to_evaluate,2) obstacles(obstacle_number_to_evaluate,2)]);
hold off;
ylim([0 1]);

% figure('name','State probabilites')
% subplot(1,2,1),plot(times(1:10:end), q_data(1:10:end,1)); title('p(free)'); ylim([0 1]);
% subplot(1,2,2),plot(times(1:10:end), q_data(1:10:end,2)); title('p(occupied)'); ylim([0 1]);

f = figure('name', 'Estimated occupancy probabilities');
movegui(f,'east');
occupancy_hmm_est(1:L) = 0;
occupancy_imac_est(1:L) = 0;
occupancy_groud_truth(1:L) = 0;
for cell_no=1:L
    q_est =  hmm_grid(cell_no).longOccupancy();
    occupancy_hmm_est(cell_no) =q_est(1);
    q_est = imac_grid(cell_no).longOccupancy();
    occupancy_imac_est(cell_no) = q_est(1);
    occupancy_groud_truth(cell_no) = occupied_count(cell_no) / N;
end

ideal_long_term(1:L) = 0;
for i=1:size(obstacles,1)
    q_est = 1.0 / (obstacles(i,2) + obstacles(i,3)) * [obstacles(i,2)  obstacles(i,3)];
    ideal_long_term(obstacles(i,1)) = q_est(1);
end
clear q_est;

bar(1:L,ideal_long_term,0.95,'FaceColor',[1 0. 0.]);
hold on
bar(1:L,occupancy_hmm_est,.75);
bar(1:L, occupancy_imac_est,0.5,'FaceColor',[0 0.7 0.7]);
% bar(1:L,occupancy_groud_truth,0.25,'FaceColor',[0 1 0]);
hold off
legend(['Static prob.';'         HMM'; '        IMAC'], 'location', 'southoutside');
% figure;
% bar([ideal_long_term; occupancy_hmm_est; occupancy_imac_est]');
% legend(['Static prob.';'         HMM'; '        IMAC']);

%% Quatify difference in occupancy maps
% hmm_divergence = kullbackDivergence(ideal_long_term, occupancy_hmm_est)
% imac_divergence = kullbackDivergence(ideal_long_term, occupancy_imac_est)