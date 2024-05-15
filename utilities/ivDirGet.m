function ourDir = ivDirGet(dirType)
%IVGETDIR Consolidated directory pathing, in progress

% Not exciting now, but once we start using datasets of frames
% and clips from acorn as well as locally, it'll get more interesting

% for host specific uses:
% get our hostName
[~, hostName] = system('hostname');
hostName = lower(strtrim(hostName));

rootDir = ivRootPath();
wslRootDir = '\\wsl$\Ubuntu-20.04\home\djc\iset\isetvideo\';
switch dirType
    case 'local'
    if isequal(hostName, 'decimate') && ispc
        ourDir = fullfile(wslRootDir, 'local');
    else
        ourDir = fullfile(rootDir, 'local');
    end
    case 'data'
        ourDir = fullfile(rootDir, 'data');
    case 'computed'
        ourDir = fullfile( rootDir, 'local', 'computed');
        if ~isfolder(ourDir)
            mkdir(ourDir);
        end
end

