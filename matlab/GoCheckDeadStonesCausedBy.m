function DeadStones = GoCheckDeadStonesCausedBy(board,move)
	Player = board(move);
	% faster than ind2sub
	[M,N,tmp] = size(board);
	Col = 1 + floor((move-1) / M);
	Row = 1 +       (move-1) - M*(Col-1);
	% check 4 neighbors
	up		= [ 0  1]';
	down	= [ 0 -1]';
	left	= [-1  0]';
	right	= [ 1  0]';
	DeadStoneBoard = zeros(size(board));
	for ij = [up down left right]
		r = Row + ij(1);
		c = Col + ij(2);
		if r >= 1 && r <= M && c >= 1 && c <= N	...	% stay in bounds
		&& board(r,c) == switchPlayer(Player)
			string = GoFindString(board,r,c);
			Alive = GoCheckLiberty(board,string);
			if ~Alive
				DeadStoneBoard = DeadStoneBoard | string;
			end
		end
	end
	DeadStones = find(DeadStoneBoard);
end

function Player = switchPlayer(Player)
Player = 3 -Player;
end