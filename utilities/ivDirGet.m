function ourDir = ivDirGet(dirType)
%IVGETDIR Consolidated directory pathing, in progress

% Not exciting now, but once we start using datasets of frames
% and clips from acorn as well as locally, it'll get more interesting

rootDir = ivRootPath();
switch dirType
    case 'local'
        ourDir = fullfile(rootDir, 'local');
    case 'data'
        ourDir = fullfile(rootDir, 'data');
end

