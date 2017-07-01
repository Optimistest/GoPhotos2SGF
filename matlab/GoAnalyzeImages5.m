clear;
topfolder = 'C:\Users\Steve\Documents\matlab\go\photos\ken 4-3-2008';
Folders = dir(topfolder);
for FolderNum = length(Folders):-1:1
	if ~Folders(FolderNum).isdir || Folders(FolderNum).name(1)=='.'
		Folders(FolderNum)=[];
	end
end
%folder = {'C:\Users\Steve\Documents\matlab\go\photos\Pergolesi 1'};
%folder = 'C:\Users\Steve\Documents\matlab\go\photos\steveVprabath1 2008-01-14 - 2008-01-14'
%folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\photos\dataset2';

% DETECT BOARDS
if 0
	for FolderNum = 1:length(Folders)
		folder = fullfile(topfolder, Folders(FolderNum).name);
		if ~exist(fullfile(folder,'Lfull.mat'),'file')
			d = dir(fullfile(folder,'*.jpg'));
			disp('Detecting Lines')
			rgb   = imread(fullfile(folder, d(1).name));
			[BW, Lines,im,Stones,rgb]= MyLineDetector4(rgb);
			disp('Detecting Board')
			Lfull = GuessSpacingRansac(BW, Lines,im,Stones,rgb);
			save(fullfile(folder, 'Lfull.mat'), 'Lfull');
		end
	end
end
% Double Check
if 0
	for FolderNum = 1:length(Folders)
		folder = fullfile(topfolder, Folders(FolderNum).name);
		d = dir(fullfile(folder,'*.jpg'));
		im = imread(fullfile(folder, d(1).name));
		Lfull = getfield(load(fullfile(folder,'Lfull'),'Lfull'),'Lfull');
		im2 = GoWarpBoard(im,Lfull);
		figure(1);clf; imagesc(im2); axis image; axis off; title(folder); pause(1)
	end
end

if 0
	for FolderNum = 1:length(Folders)
		folder = fullfile(topfolder, Folders(FolderNum).name);
		disp(folder);

		d = dir(fullfile(folder,'*.jpg'));
		FRAMES = length(d);
		SECONDS_PER_FRAME = 2;
		FRAMES_FOR_INFERENCE = 50;

		% CREATE MEDIAN-FILTERED BW IMAGES

		MedianNumber = 5;
		LowHalfMedian	= (MedianNumber-1)/2;
		if ~exist(fullfile(folder, 'mediansHSV'),'dir') && exist(fullfile(folder, 'Lfull.mat'),'file') && exist(fullfile(folder, 'board.mat'),'file')
			disp('Running Median Time-Filter to ignore Hands');
			mkdir(folder, 'mediansHSV');
			load(fullfile(folder,'Lfull'),'Lfull');
			for f=1:FRAMES
				disp(f);
				if f == 1
					im1 = rgb2hsv(imread(fullfile(folder, d(f).name)));
					im2 = GoWarpBoard(im1,Lfull);
					ims = repmat(im2, [1,1,1,MedianNumber]);
					for F = 2:(LowHalfMedian+1)
						im1 = rgb2hsv(imread(fullfile(folder, d(F).name)));
						im2 = GoWarpBoard(im1,Lfull);
						ims(:,:,:,LowHalfMedian+1) = im2;
					end
				elseif f <= FRAMES-LowHalfMedian
					F = f + LowHalfMedian;
					im1 = rgb2hsv(imread(fullfile(folder, d(F).name)));
					im2 = GoWarpBoard(im1,Lfull);
					ims = cat(4, ims(:,:,:,2:end), im2);
				else
					F = f;
					im1 = rgb2hsv(imread(fullfile(folder, d(F).name)));
					im2 = GoWarpBoard(im1,Lfull);
					ims = cat(4, ims(:,:,:,2:end), im2);
				end
				med = medianHSV(ims);
				imwrite(med, fullfile(folder, 'mediansHSV',d(f).name),'Quality',100);
			end
		end
	end
	clear ims med;
end


if 0
	for FolderNum = 1:length(Folders)
		folder = fullfile(topfolder, Folders(FolderNum).name);
		if exist(fullfile(folder, 'mediansHSV'),'dir') && exist(fullfile(folder,'board.mat'),'file') && ~exist(fullfile(folder,'probs2.mat'),'file')
			disp(folder);
			disp('Detecting Stones')
			d = dir(fullfile(folder,'*.jpg'));
			FRAMES = length(d);
			probs = zeros(19,19,FRAMES);
			allmasks = [];
			scores = zeros(19,19,2,FRAMES);
			for f = 1:FRAMES
				fprintf('Stone Detection: Frame %i / %i\n',f, FRAMES);
				hsv	= imread(fullfile(folder, 'mediansHSV', d(f).name));
				%			[probs(:,:,f),scoreN,allmasks, rectified_image] = GoFindStonesProjectGreedy(im(:,:,1),Lfull,allmasks);
				[scores(:,:,:,f),probs(:,:,f)] = GoDetectStoneSVM2(hsv);
				figure(3);
				subplot(1,2,1); imagesc(hsv); axis image; axis off;
				subplot(1,2,2); imagesc(probs(:,:,f)); axis image; axis off;
			end
			% 		pBlack = -probs;  pBlack(pBlack<0) = 0; pBlack(pBlack > 0) = scale01(log(pBlack(pBlack > 0)));
			% 		pWhite =  probs;  pWhite(pWhite<0) = 0; pWhite(pWhite > 0) = scale01(log(pWhite(pWhite > 0)));
			scores(scores < 0)	= 0;
			scores(scores > 1)	= 1;
			TotalProb = repmat(sum(scores,3),[1 1 3 1]);
			TooBig = TotalProb > 1;
			if any(TooBig(:))
				scores(TooBig) = scores(TooBig)./ TotalProb(TooBig);
			end
			for f=1:FRAMES
				probs1(:,f,1) = reshape(scores(:,:,1,f),19*19,1);
				probs1(:,f,2) = reshape(scores(:,:,2,f),19*19,1);
			end
			save(fullfile(folder,'probs2.mat'), 'probs','probs1','scores');
		end
	end
end
% Check prob score results
if 0
	for FolderNum = 1:length(Folders)
		folder = fullfile(topfolder, Folders(FolderNum).name);
		if exist(fullfile(folder, 'probs2.mat'),'file')
			load(fullfile(folder,'probs2.mat'), 'probs','probs1','scores');
			d = dir(fullfile(folder, 'mediansHSV','*.jpg'));
			FRAMES = min(length(d), size(probs,3));
			for f = 1:FRAMES
				fprintf('Replaying Stone Detection: Frame %i / %i\n',f, FRAMES);
				hsv	= imread(fullfile(folder, 'mediansHSV', d(f).name));
				figure(3); clf;
				subplot(1,2,1); imagesc(hsv);			axis image; axis off; title(folder);
				subplot(1,2,2); imagesc(-probs(:,:,f));	axis image; axis off; title(sprintf('%i/%i',f,FRAMES));
				pause(.1);
			end
		end
	end
end


for FolderNum = 6:length(Folders)
	folder = fullfile(topfolder, Folders(FolderNum).name);
	if exist(fullfile(folder, 'probs2.mat'),'file')
		disp(folder);
		probs1	= getfield(load(fullfile(folder,'probs2.mat'),'probs1'),'probs1');
		p		= reshape(probs1,19,19,[],2);
		p(end,:,:,:) = 0;
		probs1	= reshape(p,size(probs1));
		FRAMES	= size(probs1,2);
		board	= zeros(19);
		boardlist = zeros(19,19,FRAMES);
		clear nodelist;
		playerlist = zeros(FRAMES,1);
		Player = 1;
		DeadStones = [];
		LastFrame = FRAMES - 9;
%		profile on;
		for f=1:LastFrame
			fprintf('A*: Frame %i / %i\n',f, FRAMES);

			%	profile on;
			[node, score] = ChooseNextMoveAstar2(probs1(:,f:end,:), board, Player, DeadStones);
			%	profile viewer
			if f < LastFrame
				NumMovesToKeep = 1;
			else
				NumMovesToKeep = FRAMES - LastFrame;
			end
			for KeepMove = 1:NumMovesToKeep
				move = node.MovesHistory(KeepMove);
				if move > 0
					board(move)		= Player;
					if nnz(playerlist)>1 && playerlist(find(playerlist,1,'last')) == Player
						disp('two moves in a row by the same player!');
						disp('arg');
					end
					playerlist(f+KeepMove-1)	= Player;
					Player = 3-Player;
				elseif move < 0
					board(-move)	= 0;
				end
				nodelist(f+KeepMove-1)=node;
				if isempty(DeadStones) && move > 0
					DeadStones = GoCheckDeadStonesCausedBy(board,move);
				elseif ~isempty(DeadStones) && move < 0
					DeadStones(DeadStones == -move) = [];
				end
				boardlist(:,:,f+KeepMove-1) = board;
				figure(1); clf;
				p = reshape(diff(probs1(:,f+KeepMove-1,:),1,3),19,19);
				subplot(1,2,1); 	imagesc(flipud(p')); axis image; axis off; title(int2str(f+KeepMove-1));
				subplot(1,2,2); GoShowBoard(board); pause(1);
			end
		end
%		profile viewer;
		save(fullfile(folder,'MoveSequence2.mat'),'boardlist','playerlist','nodelist');
	end
end


return;

for f=1:FRAMES
	figure(1); clf;
	p = reshape(diff(probs1(:,f,:),1,3),19,19);
	subplot(1,2,1); imagesc(flipud(p')); axis image; axis off;
	subplot(1,2,2); GoShowBoard(boardlist(:,:,f));
	set(1,'Name',int2str(f));pause(.1);
end

%profile viewer;
%MAXSTONES = 6;
%coords = testGoInfer2(probs1);%,MAXSTONES);

NewSize = 19*16*[1 1];
Value	= imread(fullfile(folder, d(f).name));
[T,pts,TL,BL,BR,TR] = FindHomography(Lfull,Value);
TL2 = TL + (TL-TR)/18/2 + (TL-BL)/18/2;
BR2 = BR + (BR-TR)/18/2 + (BR-BL)/18/2;
BL2 = BL + (BL-BR)/18/2 + (BL-TL)/18/2;
TR2 = TR + (TR-TL)/18/2 + (TR-BR)/18/2;
ptsT = [TL2 BL2 BR2 TR2];
Xdata1 = [min(ptsT(2,:)) max(ptsT(2,:))];
Ydata1 = [min(ptsT(1,:)) max(ptsT(1,:))];
[M,N,channels] = size(Value);
Udata = [1 N];
Vdata = [1 M];
beep

disp('running time-inference and making movie');

% Handicap 5-stones:
%board(sub2ind([19 19],[4 4 16 16 10],[4 16 4 16 10])) = 1; % handicap stones
%Player = 2;

board = zeros(19);
Player = 1;
af = avifile('C:\Users\Steve\Documents\MATLAB\go\photos\results\pergolesi 1_2.avi',...
	'fps',1,'Compression','Cinepak');
DepthLimit = 3;
clear p s rgb im BoardPic M N c ThreeIms;
BoardSequence = zeros(19,19,FRAMES);
for f = 1:FRAMES
	[BestMove, BestScore,board] = ChooseNextMoveX(probs1(:,f:end,:), board, DepthLimit, Player);
	BoardSequence(:,:,f) = board;
	% 	[BestMove, BestScore,board,TreeVector] = ChooseNextMoveX2(probs1(:,f:end,:), board, DepthLimit, Player);
	% 	figure(10); clf; treeplot(TreeVector);
	figure(1); clf; set(1,'Name',int2str(f));
	rgb = imread(fullfile(folder, d(f).name));
	im = imrotate(imtransform(rgb,     T,'nearest','Size',NewSize, 'UData',Udata ,'VData',Vdata ,'Xdata',Xdata1,'Ydata',Ydata1),90);
	p = reshape(probs1(:,f,2)-probs1(:,f,1),[19 19])';
	s(1)=subplot(1,3,1); imagesc(im); axis image; axis off; axis xy
	s(2)=subplot(1,3,2); imagesc(p); axis image; axis off;
	s(3)=subplot(1,3,3); GoShowBoard(board); axis ij; axis off;
	if ~isempty(BestMove)
		Player = 3-Player;
	end
	BoardPic = frame2im(getframe(s(3)));
	[M,N,c] = size(BoardPic);
	ThreeIms = cat(2,scale01(im2double(imresize(flipdim(im,1),[M N]))), scale01(repmat(im2double(imresize(p,[M N],'nearest')),[1 1 3])),scale01(im2double(BoardPic)));
	%figure(2); clf;imagesc(ThreeIms); axis image
	af = addframe(af, ThreeIms);
	pause(1);
end
af=close(af);

board = zeros(19);
Player = 1;
DepthLimit = 6;
BoardSequence = zeros(19,19,FRAMES);
for f = 7:FRAMES
	disp(f);
	pause(1);
	[BestMove, BestScore,board] = ChooseNextMoveX(probs1(:,f:end,:), board, DepthLimit, Player);
	BoardSequence(:,:,f) = board;
	if ~isempty(BestMove)
		Player = 3-Player;
	end
end

if 0
	board = zeros(19,19,FRAMES);
	black = abs(min1) > abs(max1);
	white = abs(min1) < abs(max1);
	board(black) = min1(black);
	board(white) = max1(white);
	figure(1); clf;
	for f = 1:FRAMES
		imagesc(board(:,:,f)); axis image; axis off;
		colormap jet; colorbar;
		title(int2str(f));
		pause(.1)
	end
	for f = 1:FRAMES
		%		LastFrame = min(FRAMES, f+FRAMES_FOR_INFERENCE);
		%		board(:,:,f) = GoInfer(probs(:,:,f:LastFrame));
	end
end
