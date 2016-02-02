classdef BufferCell < handle
    %BUFFERFILTER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        occCnt, freeCnt;
    end
    
    methods
        function obj = BufferCell(obj)
            obj.occCnt = 0 ; 
            obj.freeCnt = 0;
        end
        
        function [] = addMeasurement(obj, m, w)
           if(m == 0)
               obj.freeCnt = obj.freeCnt + 1 * w;
           elseif(m == 1)
               obj.occCnt = obj.occCnt + 1 * w;
           end
        end
        
        function occPct = getOccupiedness(obj)
           occPct = obj.occCnt / ( obj.occCnt + obj.freeCnt );
           obj.occCnt = 0;
           obj.freeCnt = 0;
        end
    end
    
end

