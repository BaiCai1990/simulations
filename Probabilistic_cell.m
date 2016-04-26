classdef Probabilistic_cell < handle
    %PROBABILITIC_CELL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
        LOG_ODDS_UPDATE = 0.4055;
    end
    
    properties
        log_odds;
    end
    
    methods
        function obj = Probabilistic_cell()
           obj.log_odds = 0.0; 
        end
        function [] = update(obj, yt)
            if(yt > 0.5)
                obj.log_odds = obj.log_odds + obj.LOG_ODDS_UPDATE;
            else
                obj.log_odds = obj.log_odds - obj.LOG_ODDS_UPDATE;
            end
        end
        
        function occ_prob = getOccupancy_prob(obj)
            occ_prob = 1 - 1/(1+exp(obj.log_odds));
            obj.log_odds = 0.0;
        end
    end
    
end


