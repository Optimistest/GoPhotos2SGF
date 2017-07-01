function clearExcept(varargin)
% ClearExcept(variable1, variable2, ...) clears all variables except those listed
% If the listed variable does not exist, a warning is printed
%
% variable1, variable2, ... can be either:
%	(1) strings with the name of the variables to be kept
%	(2) the variables themselves, if the variable is not a string

% Example:
%	clear;
%	a=1; b=2; c={'cell'}; d = {1}; e=5; f='string'; g={'d','i','j'}; h =[1	2 3]; i=1;j=1;
%	who; %answer is "a b c d e f g h i j"
%	clearExcept('a',b,c,e,f, g{1},g{2:3},h(1), c{3:4});
%	who; %answer is "a b c d i j"
%
% Explanation:
%	a is kept because it is named
%	b is kept because it is not a string
%	c is kept because it is not a string
%	d is kept because it is named (in the string g{1})
%	e is cleared because it is not listed
%	f is cleared because it is a string
%	g is cleared because it is not listed, only g{1} (which is 'h')
%	h is cleared because h(1) is a calculated value
%	i & j are kept beacuse they are named (in the comma-separated list g{2:3} (which is 'i','j')
%
% Written by Steven Scher February 2004

for i = 1:length(varargin)
	if ~ischar(varargin{i})
		varargin{i} = inputname(i);
	end
end
variables = evalin('caller','who');
for i = 1:length(variables)
	found = 0;
	for j = 1:length(varargin)
		if strcmp(varargin{j}(1),'*') & strncmp(fliplr(varargin{j}),fliplr(variables{i}),length(varargin{j})-1) ...
		| strcmp(varargin{j}(end),'*') & strncmp(varargin{j},variables{i},length(varargin{j}-1)) ...
		| strcmp(varargin{j}, variables{i})
			found = 1;
		end
	end
	if ~found
		evalin('caller', sprintf('clear(''%s'');', variables{i}) );
	end
end
return;
