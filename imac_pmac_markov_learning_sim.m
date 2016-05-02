%% IMAC vs. PMAC ability to learn markov parameters 
%clearvars -except errors ;
clear all;
import Imc_cell
import Pmac_cell
L = 20; % Map size
map(1:L) = 0;
robot = 1;
rng('shuffle');
% Sensor
range = 19;
variance = 1.; % in grid cells

% Robot step size
robotStepSize = 0;

N = 1000;
max_std_dev = 1;
a_data_hmm(1:N,1:Hmm_EM_cell.N,1:Hmm_EM_cell.N) = -1;
a_data_imac(1:N,1:2,1:2) = -1;
a_data_pmac(1:N,1:2,1:2) = -1;
obstacle_number_to_evaluate = 1;
occupied_count(1:L) = 0;
free_count = occupied_count;
times = 1:N;
%%
% simulation of robot movements
for p_entry = 0.1:0.1:0.9
    for p_exit = 0.1:0.1:0.9
        for max_std_dev = 0.2:0.2:2
            for i=1:L
                imac_grid(i) = Imc_cell();
                pmac_grid(i) = Pmac_cell();
            end
            learner_update_count = 0;
            obstacle1 = [10,p_entry,p_exit]; % pos,free->occ, occ->free,
            for t=times
                if(mod(t,100) == 0)
                    variance = rand()*max_std_dev;
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
                
                learner_update_count = learner_update_count + 1;
                
                cell_no = obstacle1(1);
                
                if scanResult(cell_no) ~= -1
                    imac_grid(cell_no).update(scanResult(cell_no));
                    p = normcdf([-0.5 0.5],0,variance);
                    pmac_grid(cell_no).update(p(2) - p(1));
                end
                
                % Update obstacles
                if(obstacle1(1) ~= robot)
                    % Sample Bernoulli random variable
                    rn = rand(1);
                    if( rn <= obstacle1(map(obstacle1(1))+2) )
                        map(obstacle1(1)) = xor(map(obstacle1(1)),1);
                    end
                end
                a_data_pmac(learner_update_count,:,:) = pmac_grid(obstacle1(1)).getTransitionMatrix();
                a_data_imac(learner_update_count,:,:) = imac_grid(obstacle1(1)).getTransitionMatrix();
            end
            
            %% store estimation errors
            time_to_estimate = N;
            pmac_errors_entry = abs(a_data_pmac(time_to_estimate,2,1)-obstacle1(2));
            imac_errors_entry = abs(a_data_imac(time_to_estimate,2,1)-obstacle1(2));
            pmac_errors_exit = abs(a_data_pmac(time_to_estimate,1,2)-obstacle1(3));
            imac_errors_exit = abs(a_data_imac(time_to_estimate,1,2)-obstacle1(3));
            pmac_errors = (pmac_errors_entry + pmac_errors_exit)/2;
            imac_errors = (imac_errors_entry + imac_errors_exit)/2;
            
            if(exist('errors') ~= 1)
                errors(1,:) = [pmac_errors,imac_errors];
            else
                errors(size(errors,1)  + 1,:) = [pmac_errors,imac_errors];
            end
        end
    end
end