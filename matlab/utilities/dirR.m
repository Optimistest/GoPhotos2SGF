function [d,directories] = dirR(directory_name, RecursionLimit,ResultsLimit)
% Usage: [d,directories] = dirR(directory_name, RecursionLimit,ResultsLimit)
% dirR:  List directory, recursively including all subtrees (pre
%
% "dirR directory_name" lists the files in a directory. Pathnames and
%     wildcards may be used.  For example, DIR *.m lists all the M-files
%     in the current directory.
%  
% "D = DIRR('directory_name')" returns the results in an M-by-1 structure with the fields: 
%         name  -- filename
%         date  -- modification date
%         bytes -- number of bytes allocated to the file
%         isdir -- 1 if name is a directory and 0 if not
%         path  -- path to the file
%
% DIR is called to gather directory information. 
% The recursive search is in pre-order (files in current folder before subtrees)
% A recursion limit separate from the matlab get(0,'RecursionLimit') is used
%
% Created 2/20/2004 by Steve Scher


% SET DEFAULTS & HANDLE RECURSION LIMIT
if nargin < 1
	directory_name = '';
end
DefaultRecursionLimit = 50;
if nargin < 2 || isempty(RecursionLimit)
	RecursionLimit = DefaultRecursionLimit;
end
DefaultResultsLimit = Inf;
if nargin < 3
	ResultsLimit = DefaultResultsLimit;
end
MatlabRecursionLimit = get(0,'RecursionLimit');
if MatlabRecursionLimit < RecursionLimit
	RecursionLimit = MatlabRecursionLimit-1;
end
if RecursionLimit < 1
	fprintf('%s: RECURSION LIMIT REACHED IN FOLDER "%s"\n', upper(mfilename), directory_name);
	return;
end

% LOOK AT FIRST DIRECTORY
d = dir(directory_name);

% REMOVE FOLDERS FROM LIST AND ADD "PATH" TO STRUCTURE
if exist(directory_name,'dir') & isempty(findstr('/\',directory_name(end)))
	directory_name			= [directory_name filesep];
end
[PATHSTR,NAME,EXT,VERSN]	= fileparts(directory_name);
Recursions					= DefaultRecursionLimit-RecursionLimit;
for i = length(d):-1:1					% count backwards to keep index correct despite deletions
	if d(i).isdir | strncmp('.', d(i).name, 1)
		d(i)				= [];		% remove folders & hidden files
	else
		d(i).path			= PATHSTR;	% add "path" to structure
		if nargout == 0
			fprintf('%i:\t%s%s%s\n', Recursions, d(i).path, filesep, d(i).name);
		end
	end
end

% GO THROUGH ALL FOLDERS, RECURSIVELY CALLING dirR
directories	= {PATHSTR};
D			= dir(PATHSTR);
folders		= {D( [D.isdir]).name}';
for i = 1:length(folders)
	if ~strncmp('.', folders{i},1)										% skip hidden folders
		next = fullfile(PATHSTR,folders{i},[NAME EXT VERSN]);			% keep "\*xxx.123" filenames
		if isempty(strmatch(folders{i},directories))					% don't go through the same folder twice (e.g. from shortcuts)
			[new_d, new_directories] = dirR(next, RecursionLimit-1,ResultsLimit-length(d));	% RECURSIVELY CALL dirR.m, ...
			for j = 1:length(new_d)															% DECREMENTING RECURSION LIMIT & RESULTS LIMIT
				if length(d) < ResultsLimit
					d(end+1).name	= new_d(j).name;						% copy each leaf's files into main list
					d(end  ).date	= new_d(j).date;
					d(end  ).bytes	= new_d(j).bytes;
					d(end  ).isdir	= new_d(j).isdir;
					d(end  ).path	= new_d(j).path;
				end
			end
			for j = 1:length(new_directories)
				directories{end+1} = new_directories{j};
			end
		end
	end
end

if nargout == 0
	for i = 1:length(d)
		fprintf('%s\t(%s)\n', d(i).name, d(i).path)
	end
end

return;