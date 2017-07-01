function board = GoAddStone(board,coords,Player)
[M,N] = size(board);
if length(coords) == 1
	[Row,Col] = ind2sub(size(board),coords);
elseif length(coords) == 2
	Row = coords(1);
	Col = coords(2);
else
	error('?')
end
board(Row,Col) = Player;
% Check to see whether this stone kills an adjacent group
DeadStones = zeros(size(board)) ~= 0;
for i = -1:1
	for j = -1:1
		r = Row + i;
		c = Col + j;
		if xor(i,j) && c>=1 && c<=N && r>=1 && r<=M && board(r,c)~=0 && board(r,c)~=Player
			% We just removed a liberty from an adjacent enemy stone
			% Find the string
			string = GoFindString(board,r,c);
			% Check for at least one liberty
			Alive = GoCheckLiberty(board,string);
			if ~Alive
				DeadStones = DeadStones | string;
			end
		end
	end
end
% Remove the string from the board
board(find(DeadStones))=0;
return;

% function Alive = NoGoCheckLiberty(board,Row,Col,Checked)
% if nargin < 4
% 	Checked = zeros(size(board));
% 	Checked(Row,Col) = 1;
% end
% Player = board(Row,Col);
% % Check whether this stone has any liberties
% for i = -1:1
% 	for j = -1:1
% 		r = Row + i;
% 		c = Col + j;
% 		if xor(i==0,j==0) && c>=1 && c<=19 && r>=1 && r<=19 && board(r,c)==0
% 			Alive = 1;
% 			return;
% 		end
% 	end
% end
% % Check one of its neighbors that we haven't checked yet
% for i = -1:1
% 	for j = -1:1
% 		r = Row + i;
% 		c = Col + j;
% 		if xor(i==0,j==0) && c>=1 && c<=19 && r>=1 && r<=19 && board(r,c)==0 && Checked(r,c)==0
% 			Checked(r,c) = 1;
% 			Alive  = GoCheckLiberty(board,r,c,Checked);
% 			if Alive
% 				return;
% 			end
% 		end
% 	end
% end
% Alive = 0;
% return;

