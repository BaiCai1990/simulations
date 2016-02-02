classdef Hmm_EM_cell < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        N = 2; % number of states in HMM
        M = 3;
        no_of_initial_statistics_updates = 100;
    end
    
    properties
        discount_factor ; % will learn probabilities that are stable for much longer than 1/distcount_factor
        a, b, q; % model parameters
        prev_phi, cur_phi; % sufficent statistics
        t;
    end
    
    methods
        function obj =  Hmm_EM_cell(initial_prob, discount_factor, p_mess)
            obj.discount_factor = discount_factor; % 1e-3;
            obj.a(1,1) = rand(1);
            obj.a(1,2) = 1 - obj.a(1,1);
            obj.a(2,2) = rand(1);
            obj.a(2,1) = 1 - obj.a(2,2);
            obj.b = [p_mess 1-p_mess 0.5; 1-p_mess p_mess 0.5;];
            % initial state probability
            obj.q = initial_prob; % [0.05 0.95];
            % Init sufficent statistics
            obj.prev_phi(1:obj.N,1:obj.N,1:obj.M,1:obj.N) = 0;
            obj.cur_phi(1:obj.N,1:obj.N,1:obj.M,1:obj.N) = 0;
            obj.t = 0;
        end        
        function [ gamma ] = gamma_hmm(obj, l, h, yt, q )
            %GAMMA Summary of this function goes here
            %   Detailed explanation goes here
            denominator = 0;
            for m=1:obj.N
                for n=1:obj.N
                    denominator = denominator + obj.a(m,n) * obj.b(n,yt) * q(m);
                end
            end
            gamma = obj.a(l,h) * obj.b(h,yt) / denominator;            
        end
        function [] = update(obj,yt)            
            yt = 2 - yt; %[0, 1] -> [2, 1]
            if yt == 0
                yt = 3;
            end
            kron = @(n) n == 0;
            g = @(i,j,l,h) kron(i-l)*kron(j-h);
            % Update sufficent statistics
            for i=1:obj.N
                for j=1:obj.N
                    for k=1:obj.M
                        for h=1:obj.N
                            obj.cur_phi(i,j,k,h) = 0;
                            for l=1:obj.N
                                obj.cur_phi(i,j,k,h) = obj.cur_phi(i,j,k,h) + obj.gamma_hmm( l, h, yt, obj.q ) * ...
                                    (obj.prev_phi(i,j,k,l) + obj.discount_factor * (kron(yt-k) * g(i,j,l,h) * obj.q(l) - obj.prev_phi(i,j,k,l) ) );
                            end
                        end
                    end
                end
            end
            obj.prev_phi = obj.cur_phi;
            
            if obj.t >= obj.no_of_initial_statistics_updates
                % Update state probability
                prev_q = obj.q;
                obj.q(1:end) = 0;
                for l=1:obj.N
                    for m=1:obj.N
                        obj.q(l) = obj.q(l) + obj.gamma_hmm( m, l, yt, prev_q) * prev_q(m);
                    end
                end
                % Maximize transition probabilities
                for i=1:obj.N
                    for j=1:obj.N
                        obj.a(i,j) = sum(sum(obj.cur_phi(i,j,:,:) ,3) ,4) / sum(sum(sum(obj.cur_phi(i,:,:,:), 2) ,3) ,4);
                    end
                end
            end
            %obj.a
            obj.t = obj.t + 1;
        end     
        function [] = updateProject(obj)
            obj.q = obj.q * obj.a;            
        end
        
        function [q_est] = estimateOccupancy(obj)
           q_est = [0.5 0.5] * obj.a;
        end
        
        function [q_est] = longOccupancy(obj)
           q_est = 1.0 / (obj.a(2,1) + obj.a(1,2)) * [obj.a(2,1)  obj.a(1,2)];
        end
        
        function [q_est] = projectOccupancy(obj, steps)
           q_est = obj.q;
            for i=1:steps
                q_est = obj.q * obj.a;
            end
        end
    end
end
