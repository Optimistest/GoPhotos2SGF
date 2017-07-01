function boards = GoCoords2boards(coords, BoardSize)
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
