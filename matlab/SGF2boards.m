function [coords, boards] = SGF2boards(path, verbose)
if nargin < 1
	verbose = 0;
end
[coords, BoardSize, PlayerWhite,PlayerBlack] = SGFparse3(path,verbose);
NumMoves = size(coords,1);
boards = zeros(BoardSize, BoardSize, NumMoves);
Player = 1;
for m = 1:NumMoves
	if m==1
		boards(:,:,m) = GoAddStone(boards(:,:,1), coords(m,:), Player);
	else
		boards(:,:,m) = GoAddStone(boards(:,:,m-1), coords(m,:), Player);
	end
	Player = GoSwitchPlayer(Player);
end
