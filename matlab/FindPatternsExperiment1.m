clear;
SGFtopfolder = 'C:\Users\Steve\Documents\matlab\go\SGF\GoGod\Database';
yearFolders = dir(SGFtopfolder);
DesiredBoardSize = 19;
MaxMoves = 200;
probs = zeros(55,55,4,MaxMoves,'single');
MaxFiles = 10000;
AllBoards = zeros(DesiredBoardSize,DesiredBoardSize,MaxFiles, 'uint8');
for Move = 1:MaxMoves
	File = 0;
	disp(Move)
	for y = 1:length(yearFolders)
		if yearFolders(y).isdir
			SGFlist = dir(fullfile(SGFtopfolder, yearFolders(y).name, '*.sgf'));
			for s = 1:length(SGFlist)
				if ~SGFlist(s).isdir
					path = fullfile(SGFtopfolder, yearFolders(y).name, SGFlist(s).name);
					verbose = 1;
					[coords, BoardSize, PlayerWhite,PlayerBlack] = SGFparse3(path,verbose);
					NumMoves = size(coords,1);
					if BoardSize == DesiredBoardSize && NumMoves >= Move
						board = zeros(BoardSize);
						Player = 1;
						for m = 1:Move
							board = GoAddStone(board, coords(m,:), Player);
							Player = GoSwitchPlayer(Player);
						end
						File = File + 1;
						if File == 1
							AllBoards = uint8(board);
							AllBoards(1,1,MaxFiles) = 0;
						else
							AllBoards(:,:,File) = board;
						end
					end
				end
				if File > MaxFiles
					break;
				end
			end
		end
		if File > MaxFiles
			break;
		end
	end
	if File < MaxFiles
		AllBoards = AllBoards(:,:,1:File);
	end
	board = sum(AllBoards,3);
%	figure(1); clf; imagesc(scale01(board)); colorbar;

	ind = 0;
	for i = 1:10
		for j = 1:i
			ind = ind+1;
			LinearIndex(i,j) = ind;
		end
	end
	for rotate = 0:1
		AllBoards = permute(AllBoards,[2 1 3]);
		for fliplr = 0:1
			AllBoards = flipdim(AllBoards,2);
			for flipud = 0:1
				AllBoards = flipdim(AllBoards,1);
				for i = 1:10
					for j = 1:i
						ind1 = LinearIndex(i,j);
						pos1 = AllBoards(i,j,:);
						for I = 1:10
							for J = 1:I
								if i~=I && j~=J
									ind2 = LinearIndex(I,J);
									% Now we're iterating over every pair
									% of positions
									pos2 = AllBoards(I,J,:);
									probs(ind1,ind2,1,Move) = nnz( pos1 &  pos2) / File;
									probs(ind1,ind2,2,Move) = nnz(~pos1 & ~pos2) / File;
									probs(ind1,ind2,3,Move) = nnz( pos1 & ~pos2) / File;
									probs(ind1,ind2,4,Move) = nnz(~pos1 &  pos2) / File;
								end
							end
						end
					end
				end
			end
		end
	end
	for i=1:4
		figure(i);clf;
		imagesc(probs(:,:,i,Move));
		axis equal; axis off;
	end
	set(1,'Name',int2str(Move));
end
