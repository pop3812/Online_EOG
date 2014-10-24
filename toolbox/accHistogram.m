classdef accHistogram <handle
    %ACCHISTOGRAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bin = [];
        x_border = [];
        xi = [];
        nBin = 0
        delta = 0;
        data_min = 0;
        data_max = 0;
    end
    
    methods
        function obj = accHistogram()
        end
        
        function obj = Init(obj,initial_data,nBin)
            obj.nBin = nBin;
            obj.data_min = min(initial_data);
            obj.data_max = max(initial_data);
            obj.bin = zeros(1,nBin);
            obj.delta = (obj.data_max- obj.data_min)/(nBin-2);
            obj.x_border = obj.data_min:obj.delta:obj.data_max;
            
            nRow = max(size(initial_data,1),size(initial_data,2));
            for i=1:nRow
                bin_id = ceil((initial_data(i) - obj.data_min)/obj.delta)+1;
                if bin_id<1
                    bin_id = 1;
                elseif bin_id>nBin
                    bin_id = nBin;
                end
                obj.bin(bin_id) = obj.bin(bin_id) +1;
            end
            half_delta = obj.delta/2;
            obj.xi = [obj.x_border - half_delta, obj.x_border(obj.nBin-1) + half_delta];
        end
        
        function obj = add(obj,data_in)
            bin_id = ceil((data_in - obj.data_min)/obj.delta)+1;
            if bin_id<1
                bin_id = 1;
            elseif bin_id>obj.nBin
                bin_id = obj.nBin;
            end
            obj.bin(bin_id) = obj.bin(bin_id) +1;
        end
    end
    
end

