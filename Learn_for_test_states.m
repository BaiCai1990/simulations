clear all;
close all;
import Pmac_cell2
load('filter_val');
load('states_flexlab');


cell =  Pmac_cell2();
cellTrue = Pmac_cell2();
for i=1:size(filter_val,1)
    cell.update(filter_val(i));
    cellTrue.update(states(i,4));
    a_data_pmac(i,:,:) = cell.getTransitionMatrix();
    a_data_pmac_true(i,:,:) = cellTrue.getTransitionMatrix();
end

figure;
plot(a_data_pmac(:,1,2))
hold on;
plot(a_data_pmac_true(:,1,2))

figure;
plot(a_data_pmac(:,2,1))
hold on;
plot(a_data_pmac_true(:,2,1))