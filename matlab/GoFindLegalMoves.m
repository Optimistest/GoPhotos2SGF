function	LegalMoves = GoFindLegalMoves(board, Probabilities, Player, MAX_CHILDREN)
[M,N]=size(board);
E = board ==0;
obvious = E & ([zeros(N,1),		E(:,2:end)] ...
	|  [zeros(1,N);		E(2:end,:)] ...
	|  [E(:,1:end-1),	zeros(N,1)] ...
	|  [E(1:end-1,:);	zeros(1,N)]);
Empty = find(E);
EmptyProbs = Probabilities(Empty,1,Player);
[Values, Index] = sort(EmptyProbs,1,'descend');
LegalMoves = [];
if nnz(EmptyProbs) > 0
	for i=1:length(Empty)
		m = Empty(Index(i));
		%if length(LegalMoves) < MAX_CHILDREN && (obvious(m) || GoIsMoveLegal(board,m,Player) )
 		if length(LegalMoves) < MAX_CHILDREN && (obvious(m) || ~isempty(GoCheckDeadStonesCausedBy(board,m)) )
			LegalMoves(end+1) = m;
		end
	end
end
if isempty(LegalMoves)
%	disp('% No Legal Moves Above Initial Threshold');
end
return;

function MoveIsLegal = GoIsMoveLegal(board,moveIndex,Player)
Col = 1 + floor((moveIndex-1) / size(board,1));
Row = 1 +       (moveIndex-1) - size(board,1)*(Col-1);
%[Row,Col] = ind2sub(size(board),moveIndex);
for i=-1:1
	for j=-1:1
		r = Row + i;
		c = Col + j;
		if xor(i,j) && r >= 1 && r <= size(board,1) && c >= 1 && c <= size(board,2) && board(r,c)==0
			MoveIsLegal = 1;
			return;
		end
	end
end
newboard = GoAddStone(board,moveIndex,Player);
string = GoFindString(newboard,Row,Col);
MoveIsLegal = GoCheckLiberty(newboard,string);
return;
