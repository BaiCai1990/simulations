%%
clear all;
import BufferCell
import Pmac_cell
L = 10; % Map size
map(1:L) = 0;
robot = 1;

% Sensor
range = 9;
variance = 0.5; % in grid cells

% Robot step size
robotStepSize = 0;

% Obstacles
obstacle1 = [6,0.5,0.5]; % pos, free->occ, occ->free
obstacle2 = [3,0.5,0.5];

obstacles = [obstacle1; obstacle2];

% init learning models
for cell_no=2:L
    buffer_grid(cell_no) = BufferCell();
end

for cell_no=2:L
    imac_grid(cell_no) = Pmac_cell();
end

N = 1e4;

% store data for visualization of learning progress
a_data_imac(1:N,1:2,1:2) = -1;
q_data(1:N) = -1;
last_prob(1:N) = -1;
obstacle_number_to_evaluate = 1;
times = 1:N;
imac_update_interval = 1;
prev_t = 0;
%%
% simulation of robot movements
for t= times
    % Take measurement
    correct_dist = range + robot+1;
    for z=1:range;
        index = z+robot;
        if(map(index)==1)
            correct_dist = index;
            break;
        end
    end
    measured_dist = round(normrnd(correct_dist,variance));
    scanResult(1:L) = -1; % -1 = Unseen, 0 = Free, 1 = Occupied
    if measured_dist == 0
        continue;
    end
    if measured_dist > robot + range
        scanResult(robot+1:robot + range) = 0;
    else
        scanResult(robot+1:measured_dist-1) = 0;
        scanResult(measured_dist) = 1;
    end
    
    % Put scan into method
    for cell_no=2:size(scanResult,2)-1
        if scanResult(cell_no) ~= -1
            buffer_grid(cell_no-1).addMeasurement(scanResult(cell_no),0.16);
            buffer_grid(cell_no).addMeasurement(scanResult(cell_no),0.68);
            buffer_grid(cell_no+1).addMeasurement(scanResult(cell_no),0.16);
        end
    end
    cell_no = size(scanResult,2);
    if scanResult(cell_no) ~= -1
        buffer_grid(cell_no-1).addMeasurement(scanResult(cell_no),0.16);
        buffer_grid(cell_no).addMeasurement(scanResult(cell_no),0.68);
    end
    
    if mod(t, 5000) == 0
        if(obstacles(1,1) ~= robot)
            % Sample Bernoulli random variable
            rn = rand(1);
            if(rn <= obstacles(2,map(obstacles(2,1))+2))
                map(obstacles(2,1)) = xor(map(obstacles(2,1)),1);
            end
        end
    end
    if mod(t, 10000) == 0
            % Update obstacles
        if(obstacles(1,1) ~= robot)
            % Sample Bernoulli random variable
            rn = rand(1);
            if(rn <= obstacles(1,map(obstacles(1,1))+2))
                map(obstacles(1,1)) = xor(map(obstacles(1,1)),1);
            end
        end
    end
    
    if (t - prev_t) >= imac_update_interval
        prev_t = t;
        % Update IMAC
        for cell_no=1:size(buffer_grid,2)
            occupied_ness = buffer_grid(cell_no).getOccupiedness();
            if buffer_grid(cell_no).isUpdated                
                imac_grid(cell_no).update(occupied_ness, t);
            end
            if(cell_no == obstacles(obstacle_number_to_evaluate,1))
                q_data(t) = occupied_ness;
                last_prob(t) = imac_grid(cell_no).last_prob_occ;
            end
            buffer_grid(cell_no).reset();            
        end
    end
    a_data_imac(t,:,:) = imac_grid(obstacles(obstacle_number_to_evaluate,1)).getTransitionMatrix();
    if mod(t, N / 10) == 0
        procent_gone = t/N * 100
    end
end

%% Display learning results
close all;
plot_resolution = 1;

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
f = figure('name', 'Estimated occupancy probabilities');
movegui(f,'east');
occupancy_imac_est(1:L) = 0;
for cell_no=1:L
    q_est = imac_grid(cell_no).longOccupancy();
    occupancy_imac_est(cell_no) = q_est(1);
end

ideal_long_term(1:L) = 0;
for i=1:size(obstacles,1)
    q_est = 1.0 / (obstacles(i,2) + obstacles(i,3)) * [obstacles(i,2)  obstacles(i,3)];
    ideal_long_term(obstacles(i,1)) = q_est(1);
end
clear q_est;

bar(1:L,ideal_long_term,0.95,'FaceColor',[1 0. 0.]);
hold on
bar(1:L, occupancy_imac_est,0.5,'FaceColor',[0 0.7 0.7]);
hold off
ylim([0 1]);
legend(['Static prob.'; '        IMAC'], 'location', 'southoutside');
% figure;
% bar([ideal_long_term; occupancy_hmm_est; occupancy_imac_est]');
% legend(['Static prob.';'         HMM'; '        IMAC']);
figure;
plot(times,q_data);
hold on;
plot(times, last_prob);
hold off;
%% Quatify difference in occupancy maps
% hmm_divergence = kullbackDivergence(ideal_long_term, occupancy_hmm_est)
% imac_divergence = kullbackDivergence(ideal_long_term, occupancy_imac_est)