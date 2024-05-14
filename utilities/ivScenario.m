classdef ivScenario < handle
    %IVSCENARIO construct for running video scenes
    %   D. Cardinal, Stanford University, 2024
    
    properties
        sceneName = 'pavilion-day';
        exposureTime = 1/30;
        clipLength = 1/15;
        raysPerPixel = 1024;
        fastPreview = 1;

    end
    
    methods
        function obj = ivScenario(sceneName)
            %IVSCENARIO Construct an instance of this class
            obj.sceneName = sceneName;
        end
        
    end
end

