classdef Pmac_cell < handle
    %Pmac_cell Summary of this class goes here
    %   Detailed explanation goes here
    properties(Constant)
        max_N = 1e4;
        recency_weightning = 2000/2001;
        OCCUPIED = 1, FREE = 0;
        no_of_initial_statistics_updates = 100;
    end
    
    properties
        obs_occ, obs_free;
        release; % occupied -> free
        entry; % free -> occupied
        last_obs;
        unknown_since_last_obs;
        t;
        prev_state_score;
        occ_before, free_after;
        free_before, occ_after;
        occ_count, free_count;
    end
    
    methods
        function obj = Pmac_cell()
            obj.obs_occ = realmin('double');
            obj.obs_free = realmin('double');
            obj.release = realmin('double');
            obj.entry = realmin('double');
            obj.last_obs = 0;
            obj.unknown_since_last_obs = 0;
            obj.t = 0;
            obj.prev_state_score = 0;
            obj.occ_before=0;
            obj.free_after=0;
            obj.free_before=0;
            obj.occ_after=0;
            obj.occ_count = 0;
            obj.free_count = 0;
        end
        function [] = update(obj,occ_prob)         
            if(occ_prob > 0.5)
                occ_score = (occ_prob-0.5)*2;
                obj.obs_occ = obj.obs_occ + occ_score;
                if(obj.last_obs < 0.5)
                    obj.release = obj.release + min([obj.occ_before/obj.occ_count,obj.free_after,1]);
                    %obj.entry = obj.entry + obj.prev_state_score;%min(occ_score, obj.prev_state_score);
                    obj.occ_before = 0.0;
                    obj.free_after = 0.0;
                    obj.occ_count = 0;
                end
                obj.occ_after = obj.occ_after + occ_score;
                obj.occ_before = obj.occ_before + occ_score;
                obj.prev_state_score = occ_score;
                obj.occ_count = obj.occ_count + 1;
            else
                free_score = ((1-occ_prob)-0.5)*2;
                obj.obs_free = obj.obs_free + free_score;
                if(obj.last_obs > 0.5)
                    obj.entry = obj.entry + min([obj.free_before/obj.free_count,obj.occ_after,1]);
                    %obj.release = obj.release + obj.prev_state_score;%min(free_score, obj.prev_state_score);
                    obj.free_before = 0.0;
                    obj.occ_after = 0.0;
                    obj.free_count = 0;
                end
                obj.free_after = obj.free_before + free_score;
                obj.free_before = obj.free_before + free_score;
                obj.prev_state_score = free_score;
                obj.free_count = obj.free_count + 1;
            end
            obj.last_obs = occ_prob;
            
            %             free_prob = (1-occ_prob);
            %             obj.obs_occ = obj.obs_occ + occ_prob;
            %
            %             obj.obs_free = obj.obs_free + free_prob;
            %
            %             event_counter = occ_prob - obj.last_obs;
            %
            %             if(event_counter > 0)
            %                 obj.entry = obj.entry + event_counter;
            %             else
            %                 obj.release = obj.release + -event_counter;
            %             end
            %
            %
            
            % update estimate
            %             if yt == obj.OCCUPIED
            %                 obj.obs_occ = obj.obs_occ + obj.p_occ;
            %                 % change ?
            %                 if obj.last_obs == obj.FREE
            %                     obj.entry = obj.entry + obj.p_free;
            %                 end
            %             else
            %                 obj.obs_free = obj.obs_free + obj.p_free;
            %                 % change ?
            %                 if obj.last_obs == obj.OCCUPIED
            %                     obj.release = obj.release + obj.p_occ;
            %                 end
            %             end
            
            %             % recency weightning
            %             if yt == obj.OCCUPIED
            %                 % update active state
            %                 if obj.obs_occ > obj.max_N
            %                     obj.release = obj.release * obj.max_N / obj.obs_occ;
            %                 end
            %                 % update inactive state
            %                 obj.entry = 1 + (obj.entry - 1) * obj.recency_weightning;
            %                 obj.obs_free = 1 + (obj.obs_free - 1) * obj.recency_weightning;
            %             else
            %                 % update active state
            %                 if obj.obs_free > obj.max_N
            %                     obj.entry = obj.entry * obj.max_N / obj.obs_free;
            %                 end
            %                 % update inactive state
            %                 obj.release = 1 + (obj.release - 1) * obj.recency_weightning;
            %                 obj.obs_occ = 1 + (obj.obs_occ - 1) * obj.recency_weightning;
            %             end
            
            obj.unknown_since_last_obs = 0;
            
            % prepare for next update
            
        end
        
        function a = getTransitionMatrix(obj)
            lambda_entry = (obj.entry) / (obj.obs_free);
            lambda_exit = (obj.release) / (obj.obs_occ);
            
            % correct for using mobile observer
            %             if (obj.obs_free + obj.obs_occ) > obj.no_of_initial_statistics_updates
            %                 lambda_exit = sqrt(4*lambda_exit + 1) / 2 - 0.5;
            %                 lambda_entry = -(lambda_exit * lambda_entry) / (lambda_entry - lambda_exit);
            %
            %                 if lambda_exit < 0 || lambda_entry < 0
            % %                     lambda_entry = (obj.entry + 1) / (obj.obs_free + 1);
            % %                     lambda_exit = (obj.release + 1) / (obj.obs_occ + 1);
            %                     disp('underflow');
            %                 elseif lambda_exit > 1 || lambda_entry > 1
            % %                     lambda_entry = (obj.entry + 1) / (obj.obs_free + 1);
            % %                     lambda_exit = (obj.release + 1) / (obj.obs_occ + 1);
            %                     disp('overflow');
            %                 end
            %             end
            a(1:2,1:2) = [1-lambda_exit, lambda_exit; lambda_entry, 1-lambda_entry];
        end
        
        function updateProject(obj)
            obj.unknown_since_last_obs = obj.unknown_since_last_obs + 1;
        end
        
        function [est_q] = project(obj)
            if obj.last_obs == obj.FREE
                q = [1 0];
            else
                q = [0 1];
            end
            q_est = q * obj.a;
        end
        
        function [q_est] = estimateOccupancy(obj)
            a = obj.getTransitionMatrix();
            est_q = [0.5 0.5];
            for i=1:obj.unknown_since_last_obs
                est_q = q_est * a;
            end
        end
        
        function [q_est] = longOccupancy(obj)
            a = obj.getTransitionMatrix();
            q_est = 1.0 / (a(2,1) + a(1,2)) * [a(2,1)  a(1,2)];
        end
        
        function [q_est] = projectOccupancy(obj, steps)
            a = obj.getTransitionMatrix();
            q_est = 0;
            for i=1:steps
                q_est = obj.q * a;
            end
        end
    end
    
end

