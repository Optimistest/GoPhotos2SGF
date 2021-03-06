function key = GoBoardHash(board, Player, move)
persistent BoardOfRands;
if isempty(BoardOfRands)
	oldseed = rand('twister');
	newseed = 5489;
	rand('twister',newseed);
	BoardOfRands = rand(19,19,3);
	rand('twister',oldseed);
end
board3 = cat(3,board==0, board==1, board==2);
key = sum(sum(BoardOfRands(board3)));
if nargin > 1 && Player == 1
	key = key + 19*19*3;
end
if nargin > 2
	key = key + 19*19*3*2 * move;
end
