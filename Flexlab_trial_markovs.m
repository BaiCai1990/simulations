clear all
obstacle1 = [0.8,0.8]; %free->occ, occ->free,
obstacle2 = [0.8,0.5];
obstacle3 = [0.0,0.0]; % DUMMY
obstacle4 = [0.2,0.2];
obstacle5 = [0.2,0.5];
obstacle6 = [0.5,0.5];
obstacle7 = [0.8,0.2];
obstacle8 = [0.6,0.9];
obstacle9 = [0.1,0.85];
obstacle10 = [0.3,0.4];

rng('shuffle');

obstacles = [obstacle1;obstacle2;obstacle3;obstacle4;obstacle5;obstacle6;obstacle7;obstacle8;obstacle9;obstacle10];
steps = 1000;
states(steps,size(obstacles,1)) = -1;% 0(free) 1(occ)
states(1,:) = zeros(size(obstacles,1),1); 

for m=2:steps % markov steps
    for i=1:size(obstacles,1)
        rn = rand(1);
        if( rn <= obstacles(i,states(m-1,i)+1))
            new_val = xor(states(m-1,i),1);
        else
            new_val = states(m-1,i);
        end
        states(m,i) = new_val;
    end
end

for i=1:9
   sums(i) = sum(states(:,i)); 
end
sums

