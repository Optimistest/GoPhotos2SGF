function string = GoFindString(board,Row,Col,string,Player)
[M,N] = size(board);
if nargin < 4,
	string = zeros(size(board))~= 0;
	Player = board(Row,Col);
	if Player ~= 0
		string(Row,Col) = 1;
	else
		return;
	end
end
for i = -1:1
	for j = -1:1
		r = Row + i;
		c = Col + j;
		if xor(i,j) && c>=1 && c<=N && r>=1 && r<=M && board(r,c)==Player && string(r,c)==0
			string(r,c) = 1;
			string = GoFindString(board,r,c,string,Player);
		end
	end
end
return;
