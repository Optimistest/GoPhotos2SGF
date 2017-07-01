function Alive = GoCheckLiberty(board,string)
[M,N] = size(board);
Alive = 0;
[I,J] = find(string);
for k=1:length(I)
	for i = -1:1
		for j = -1:1
			r = I(k) + i;
			c = J(k) + j;
			if xor(i,j) && c>=1 && c<=N && r>=1 && r<=M && board(r,c)==0
				Alive = 1;
				return;
			end
		end
	end
end
return;
