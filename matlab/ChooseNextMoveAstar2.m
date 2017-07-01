function [node, score] = ChooseNextMoveAstar1(Probabilities, board, Player, DeadStones)
	global QueueOfNodes NumNodes ScoreEstimates EmptyNode BestFinishedNode QueueOfScores TranspositionTable;
	global MAX_CHILDREN MAX_DEPTH;
	MAX_CHILDREN	= 5;
	MAX_DEPTH		= min(30, size(Probabilities,2));
	MAX_ITERS				= 5000;

	MaxNodes				= 5000;
	EmptyNode				= struct('score', [], 'KnownScores',[], 'MovesHistory', [], 'PlayerHistory', [], ...
		'board',zeros(19), 'depth', [], 'Player',[], 'key',[], 'DeadStones',[]);
%	BestNodeSoFar			= EmptyNode;

	TranspositionTable		= java.util.Hashtable(MaxNodes);
	BestFinishedNode		= EmptyNode;
	BestFinishedNode.score	= inf;
	QueueOfNodes			= EmptyNode;
	for i=MaxNodes:-1:2
		QueueOfNodes(i)		= EmptyNode;
	end
	QueueOfScores			= inf*ones(1,MaxNodes);
	NumNodes				= 0;
	
	
	Pblack					= Probabilities(:,:,1);
	Pwhite					= Probabilities(:,:,2);
	Pempty					= 1-(Pblack+Pwhite);
	if any(Pblack(:) + Pwhite(:) > 1) || any(Pblack(:) < 0) || any(Pwhite(:) < 0)
		error('Error: probabilities must be between 0 and 1');
	end
	probs					= cat(3,Pblack, Pwhite, Pempty);
	maxprobs				= max(probs, [], 3);
	ScoreEstimates			= sum(Prob2Score(maxprobs), 1);
	
	
	FirstNode				= EmptyNode;
	FirstNode.depth			= -1;
	if nargin >= 4 && ~isempty(DeadStones)
		FirstNode.DeadStones	= DeadStones;
	end
	InsertNode(0, board, 0, FirstNode, Player);
	i = 1;
	tic;
	while i <= MAX_ITERS && NumNodes >= 1 
		if toc > 5
			disp([i NumNodes]);
			figure(2); clf; hist(QueueOfScores(1:NumNodes),30); xlim([100 500]);
			tic;
		end
		[node, score, index] = PeekMinUnfinished;
		if score >= BestFinishedNode.score
			break;
		end
%		figure(2); clf; GoShowBoard(node.board); pause(.1);
		RemoveNode(index);
		ExpandNode(node, Probabilities);
		i=i+1;
	end
	if isempty(BestFinishedNode.depth)
		[node, score] = PeekMinUnfinished;
	else
		node	= BestFinishedNode;
		score	= BestFinishedNode.score;
	end
	clear global QueueOfNodes NumNodes ScoreEstimates MAX_CHILDREN MAX_DEPTH BestFinishedNode;
end

function InsertNode(boardscore, board, move, parent, Player)
	global QueueOfNodes NumNodes MAX_DEPTH ScoreEstimates BestFinishedNode QueueOfScores TranspositionTable;

	% create new node to insert
	child							= parent;
	child.Player					= Player;
	child.depth						= parent.depth + 1;
	child.board						= board;
	child.key						= GoBoardHash(child.board, child.Player, child.depth);
	if child.depth > 0
		child.KnownScores(child.depth)	= boardscore;
		child.score						= sum(child.KnownScores) + sum(ScoreEstimates(child.depth+1:MAX_DEPTH));
		child.MovesHistory(end+1)		= move;
		if move > 0
			child.PlayerHistory(end+1)	= parent.Player;
		else
			child.PlayerHistory(end+1)	= 0;
		end
		if move > 0 && isempty(parent.DeadStones)
			child.DeadStones = GoCheckDeadStonesCausedBy(board,move);
		elseif move < 0 && ~isempty(parent.DeadStones)
			child.DeadStones(parent.DeadStones == abs(move)) = [];
		end
	else
		child.score						= sum(ScoreEstimates(1:MAX_DEPTH));
	end
	% we only need one finished node - the best one so far
	if child.depth >= MAX_DEPTH
		if child.score < BestFinishedNode.score
			BestFinishedNode = child;
			NewlyTooHigh = ~isinf(QueueOfScores) & QueueOfScores >= BestFinishedNode.score;
			fprintf('new best node');
			if any(NewlyTooHigh)
				RemoveNode(find(NewlyTooHigh));
				fprintf(', pruned %d nodes', nnz(NewlyTooHigh));
			end
			fprintf('\n');
		end
		return;
	end
	% we don't need any nodes that can't possibly be better than the best so far
	if child.score >= BestFinishedNode.score
		return;
	end

	oldscore = TranspositionTable.get(child.key);
	if ~isempty(oldscore)
		if child.score >= min(oldscore)
			return;					% Don't insert a new node if the queue contains the same state with a better score
		else
			% Find the old node & remove it so we can replace it with this
			% better node
			
			PossibleTranspositions			= find([QueueOfNodes.key] == child.key);
			for i = PossibleTranspositions
				if child.depth == QueueOfNodes(i).depth ...
				&& child.Player == QueueOfNodes(i).Player ...
				&& all(child.board(:) == QueueOfNodes(i).board(:)) ...
				&& (  (isempty(child.DeadStones)&&isempty(QueueOfNodes(i).DeadStones))  || isempty(setxor(child.DeadStones, QueueOfNodes(i).DeadStones))  ) ...
				&& child.score < QueueOfNodes(i).score
					RemoveNode(i);		% Remove the old node if it has the same state with a worse score
				end
			end
		end
	end

	% Check for a node already in the Queue with the same state
	%      (board, depth, Player)

	% Insert the node
	if NumNodes >= length(QueueOfNodes)
		[worst_score, worst_index] = max(QueueOfScores);
		if child.score > worst_score
			return;
		else
			RemoveNode(worst_index);
		end
	end
	NumNodes						= NumNodes + 1;
	QueueOfNodes(NumNodes)			= child;
	QueueOfScores(NumNodes)			= child.score;
	TranspositionTable.put(child.key, child.score);
end

function RemoveNode(index)
	global QueueOfNodes NumNodes EmptyNode QueueOfScores;
	if any(isnan(index))
		disp('index is NaN');
		keyboard;
	end
	NumToRemove = length(index);
	keep = true(length(QueueOfNodes),1);
	keep(index) = false;
	QueueOfNodes = [QueueOfNodes(keep) repmat(EmptyNode,1,NumToRemove)];
	QueueOfScores = [QueueOfScores(keep) inf(1,NumToRemove)];
	NumNodes = NumNodes - NumToRemove;
end

function [node, score, index] = PeekMinUnfinished
	global QueueOfNodes NumNodes QueueOfScores;
	if NumNodes > 0
%		[score, index]	= min([QueueOfNodes.score]);
		[score, index]	= min(QueueOfScores);
		node		= QueueOfNodes(index);
		return;
	end
	node = struct([]);
	score = inf;
	index = NaN;
end


function ExpandNode(parent, Probabilities)
	global MAX_CHILDREN;
%	if isempty(parent.DeadStones)
%		parent.DeadStones = GoFindDeadStones(parent.board,switchPlayer(parent.Player));
%	end
	if ~isempty(parent.DeadStones)
		NumLegalMoves = length(parent.DeadStones);
		scores = zeros(1,NumLegalMoves+1);
		for i = 1:NumLegalMoves
			newboard = parent.board;
			newboard(parent.DeadStones(i)) = 0;
			scores(i) = GoScoreThisBoard(Probabilities(:,parent.depth+1,:),newboard);
		end
		scores(NumLegalMoves+1) = GoScoreThisBoard(Probabilities(:,parent.depth+1,:),parent.board);
		scores = scores / (NumLegalMoves+1);
		[SortedScores,Index] = sort(scores,'ascend');
		if NumLegalMoves > MAX_CHILDREN
			Index = Index(1:MAX_CHILDREN);
		end
		for i = 1:length(Index)
			if Index(i) <= NumLegalMoves
				newboard = parent.board;
				newboard(parent.DeadStones(Index(i))) = 0;
				InsertNode(scores(Index(i)), newboard, -parent.DeadStones(Index(i)), parent, parent.Player);		% Remove a stone
			else
				InsertNode(scores(Index(i)), parent.board, 0, parent, parent.Player);	% No Change
			end
		end
	else
		LegalMoves = GoFindLegalMoves(parent.board, Probabilities(:,parent.depth+1,:), parent.Player, MAX_CHILDREN);
		NumLegalMoves = length(LegalMoves);
		scores = zeros(1,NumLegalMoves+1);
		for i = 1:NumLegalMoves
			newboard = parent.board;
			newboard(LegalMoves(i)) = parent.Player;
			scores(i) = GoScoreThisBoard(Probabilities(:,parent.depth+1,:),newboard);
		end
		scores(NumLegalMoves+1) = GoScoreThisBoard(Probabilities(:,parent.depth+1,:),parent.board);
%		scores = scores / (NumLegalMoves+1);
		[SortedScores,Index] = sort(scores,'ascend');
		if NumLegalMoves > MAX_CHILDREN
			Index = Index(1:MAX_CHILDREN);
		end
% 		if any(any(Probabilities(LegalMoves,parent.depth+1,:)))
% 			figure(2); clf;
% 			subplot(ceil(sqrt(MAX_CHILDREN+1)), ceil(sqrt(MAX_CHILDREN+1)), 1);
% 			p = reshape(diff(Probabilities(:,parent.depth+1,:),1,3),19,19);
% 			imagesc(flipud(p')); axis image; axis off; colorbar; title(sprintf('Depth=%i, Player=%i', parent.depth+1,parent.Player));
% 		end
		for i = 1:length(Index)
			if Index(i) <= NumLegalMoves
				newboard = parent.board;
				newboard(LegalMoves(Index(i))) = parent.Player;
% 				if any(any(Probabilities(LegalMoves,parent.depth+1,:)))
% 					subplot(ceil(sqrt(MAX_CHILDREN+1)), ceil(sqrt(MAX_CHILDREN+1)), i+1);
% 					GoShowBoard(newboard);
% 					axis off;
% 					title(num2str(scores(Index(i))));
% 				end
				InsertNode(scores(Index(i)), newboard, LegalMoves(Index(i)), parent, switchPlayer(parent.Player));		% Add a stone
			else
				InsertNode(scores(Index(i)), parent.board, 0, parent, parent.Player);		% No Change
			end
		end
		% Special Handicap Move allowance - before any white stones are
		% played, black can play several stones on star points
		if parent.Player == 2 ...												% should be white's turn
		&& isempty(parent.PlayerHistory) || ~any(parent.PlayerHistory == 2)	... % no white stones yet
		&& all(parent.PlayerHistory==0 | isMoveHandicap(parent.PlayerHistory))	% black stones only on star points
			parent.Player = 1;
			LegalMoves = GoFindLegalMoves(parent.board, Probabilities(:,parent.depth+1,:), parent.Player, MAX_CHILDREN);
			LegalMoves = intersect(LegalMoves, handicapStones);
			NumLegalMoves = length(LegalMoves);
			scores = zeros(1,NumLegalMoves);
			for i = 1:NumLegalMoves
				newboard				= parent.board;
				newboard(LegalMoves(i)) = parent.Player;
				scores(i)				= GoScoreThisBoard(Probabilities(:,parent.depth+1,:),newboard);
			end
%			scores					= scores / (NumLegalMoves);
			[SortedScores,Index]	= sort(scores,'ascend');
			if NumLegalMoves > MAX_CHILDREN
				Index = Index(1:MAX_CHILDREN);
			end
			for i = 1:length(Index)
				newboard						= parent.board;
				newboard(LegalMoves(Index(i)))	= parent.Player;
				InsertNode(scores(Index(i)), newboard, LegalMoves(Index(i)), parent, switchPlayer(parent.Player));		% Add a stone
			end
		end
	end
end

function score = Prob2Score(prob)
	score = -log2(eps + (1-eps)*prob);
end

function score = GoScoreThisBoard(probs,board)
	warnstate	= warning('Query','MATLAB:log:logOfZero');
				  warning('On','MATLAB:log:logOfZero');
	score		= 0;
	Pblack		= probs(:,:,1);			score = score + sum(Prob2Score(Pblack(board==1)));
	Pwhite		= probs(:,:,2);			score = score + sum(Prob2Score(Pwhite(board==2)));
	Pempty		= 1-(Pblack+Pwhite);	score = score + sum(Prob2Score(Pempty(board==0)));
				  warning(warnstate.state,'MATLAB:log:logOfZero');
end

function DeadStones = GoFindDeadStones(board,Player)
	DeadStones = zeros(size(board));
	Checked = board~=Player;
	CheckMe = find(~Checked(:),1);
	while ~isempty(CheckMe)
		Col = 1 + floor((CheckMe-1) / size(board,1));
		Row = 1 +       (CheckMe-1) - size(board,1)*(Col-1);
	%	[Row,Col] = ind2sub(size(board),CheckMe);
	%	disp([CheckMe NaN Row Col])
		string = GoFindString(board,Row,Col);
		Alive = GoCheckLiberty(board,string);
		if ~Alive
			DeadStones = DeadStones | string;
		end
		Checked(string) = 1;
		CheckMe = find(Checked(:)==0,1);
	end
	DeadStones = find(DeadStones(:));
end

function Player = switchPlayer(Player)
	Player = 3 - Player;
end

function out = handicapStones
	persistent starpoints;
	if isempty(starpoints)
		[x,y]=meshgrid([4 10 16],[4 10 16]);
		starpoints = sub2ind([19 19],x,y);
	end
	out = starpoints(:);
end
function out = isMoveHandicap(move)
%	[Row,Col]=ind2sub([19 19],move);
	Col = 1 + floor((move-1) / 19);
	Row = 1 +       (move-1) - 19*(Col-1);
	out = ismember(Row, [4 10 16]) & ismember(Col, [4 10 16]);
end
