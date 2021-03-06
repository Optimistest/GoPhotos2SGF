function [coords, BoardSize, PlayerWhite,PlayerBlack] = SGFparse3(path,verbose)
if nargin < 1
	folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\SGF';
	file = fullfile(folder, 'good_game.sgf');	
elseif exist(path,'file')
	file = path;
elseif exist(path,'dir')
	d=dir(fullfile,[path '*.sgf']);
	file = d(1);
end
BoardSize = 19;
PlayerWhite = [];
PlayerBlack = [];

fid = fopen(file,'rt');
SGFcell = textscan(fid,'%c');
fclose(fid);
SGF = SGFcell{1}';
SGF = SGF(~isspace(SGF));
MAXNODES = 300;
%Tree = 
%Root = struct('Move',move,'children',struct([]));
%CurrentNode = 0;
Board = zeros(19);

if nargout == 0
	figure(1); clf;
	rectangle('Position', [.5 .5 19 19],'Curvature',[0 0],'FaceColor',hex2dec(['85'; '5E'; '42'])/255);
	axis equal; axis([0 20 0 20]); 
	for L = 1:19
		line([L L],[1 19],'Color','k');
		line([1 19],[L L],'Color','k');
	end
end
move = 0;
coords = [];
while ~isempty(SGF)
	if strcmp(SGF(1), '(') & strcmp(SGF(end),')')
		left  = SGF == '(';
		right = SGF == ')';
		TooManyLeft = cumsum(-left + right);
		FirstZero = find(TooManyLeft == 0,1,'first');
		if FirstZero == length(SGF)
			% (1) extraneous parentheses - remove them
			SGF = SGF(2:end-1);
			if nargout == 0
				disp('Removed Enclosing ()')
			end
		else
			% (2) split: must find break between 2 branches
			SubString1 = SGF(2:FirstZero-1);
			SubString2 = SGF(FirstZero+1:end);
%			Root = ParseSGFstring(Root, SubString1, SubString2);
			if nargout == 0
				fprintf('splitting into substrings:\n%s\n%s\n')
				fprintf('Not yet implemented.  Only using first substring');
			end
			SGF = SubString1;
		end
	elseif strcmp(SGF(1),';')
		% next node on this line
		SGF = SGF(2:end);
		if nargout == 0
			disp(';')
		end
	elseif ~isempty(strfind('ABCDEFGHIJKLMNOPQRSTUVWXYZ',SGF(1)))
		NameLength = find(isstrprop(SGF,'upper')==0,1,'first');
		PropName = SGF(1:NameLength-1);
		SGF = SGF(NameLength:end);
		if ~strcmp(SGF(1),'[')
			coords = NaN;
			fprintf('Error reading file, expected [\n File: %s\n',file)
			return;
		end
		while ~isempty(SGF) && strcmp(SGF(1),'[')
			left = SGF == '[';
			right = SGF == ']';
			TooManyLeft = cumsum(-left + right);
			FirstZero = find(TooManyLeft == 0,1,'first');
			PropValue = SGF(2:FirstZero-1);
			SGF = SGF(FirstZero+1:end);

			if strcmp(PropName,'B') || strcmp(PropName,'W')
				move = move+1;
				if (isempty(PropValue) || strcmp(PropValue,'tt'))  &&  nargout == 0
					title(sprintf('Pass by %s',PropName));
					coords(move,:) = [20 20];
				elseif ~isempty(PropValue)
					RowCol = double(   lower(PropValue) - 'a') + 1;
					Board(RowCol(1),RowCol(2)) = PropName;
					if nargout == 0
						figure(1); hold on;
						if strcmp(PropName,'B')
							Board(RowCol(1),RowCol(2)) = rectangle('Position',[RowCol-.5, 1,1],'Curvature',[1 1],'FaceColor','k');
						elseif strcmp(PropName,'W')
							Board(RowCol(1),RowCol(2)) = rectangle('Position',[RowCol-.5, 1,1],'Curvature',[1 1],'FaceColor','w');
						end
						text(RowCol(1),RowCol(2),int2str(move),'Color','r','HorizontalAlignment','Center');
					else
						coords(move,:) = RowCol;
					end
				end
			elseif strcmp(PropName,'TW') || strcmp(PropName,'TB')
				%error('Territory - not yet implemented');
				RowCol = double(   lower(PropValue) - 'a') + 1;
				if nargout == 0
					if strcmp(PropName(2),'B')
						rectangle('Position',[RowCol-.05, .1,.1],'Curvature',[1 1],'FaceColor','k');
					elseif strcmp(PropName(2),'W')
						rectangle('Position',[RowCol-.05, .1,.1],'Curvature',[1 1],'FaceColor','w');
					end
				end
			elseif strcmp(PropName,'PW')
				PlayerWhite = PropValue;
			elseif strcmp(PropName,'PB')
				PlayerBlack = PropValue;
			elseif strcmp(PropName,'SZ')
				LastDigit = find(cumsum(isstrprop(PropValue,'digit')) == (1:length(PropValue)),1,'last');
				BoardSize = eval(PropValue(1:LastDigit));
			else
				if nargout == 0
					fprintf('Property: %s\tValue: %s\n',PropName, PropValue);
					if strcmp(PropName,'GM')
						if strcmp(PropValue,'1')
							fprintf('Game Type is *Go*\n')
						else
							fprintf('Game Type is unknown: %s\n', PropValue);
						end
					end
				end
			end
		end
	else
		fprintf('error in SGFparse, expected "(", ";", or FIELDNAME\n')
		coords = NaN;
		return;
	end
end
