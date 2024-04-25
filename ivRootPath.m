function rootPath=ivRootPath()
% Return the path to the root ISETVideo directory
%
% This function must reside in the directory at the base of the
% ISETVideo directory structure.  It is used to determine the location
% of various sub-directories.
% 

rootPath=which('ivRootPath');

[rootPath,fName,ext]=fileparts(rootPath);

end
