%clear; clc;
%folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\SGF\DavdJarvisJigo-sgf-games\games';
folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\SGF\GoGod\Database'
MAXGAMES = 100;
MAXLENGTHparams = [40 120];
MINGAMELENGTH = max(MAXLENGTHparams);

Players = struct([]);%'name',[],'games',[]);
GameNum = 1;
tic;
% Loop over folders
f	= dir(folder);
f	= f([f.isdir]);
for i=1:length(f)
	% Loop over Games
	Games = dir(fullfile(folder,f(i).name,'*.sgf'));
	for g = 1:length(Games)
		if GameNum <= MAXGAMES
			% Read Game
			[coords, BoardSize, PlayerWhite,PlayerBlack] = SGFparse3(fullfile(folder, f(i).name, Games(g).name));
			if toc > 2
				disp(GameNum); tic;
			end
			if length(coords)>MINGAMELENGTH && ~any(isnan(coords(:))) &&  BoardSize == 19
				for MirrorSymmetry = 0:1
					for RotateSymmetry = 0:3
						if MirrorSymmetry
							coords = fliplr(coords);
						end
						for r = 1:RotateSymmetry
							coords = [20-coords(:,2), coords(:,1)];
						end
						IndexSymmetry = 1+MirrorSymmetry*4 + RotateSymmetry;
						AllCoords(GameNum+IndexSymmetry).coords = coords;
						AllCoords(GameNum+IndexSymmetry).GameNum= GameNum;
						% Find player #'s, or if a player is new, make a new entry
						BlackInd = [];
						for p=1:length(Players)
							if strcmpi(PlayerBlack,Players(p).name)
								BlackInd = p;
								Players(p).games = [Players(p).games GameNum+IndexSymmetry];
								break;
							end
						end
						if isempty(BlackInd)
							if isempty(Players)
								Players = struct('name',PlayerBlack,'games',GameNum+IndexSymmetry);
							else
								Players(end+1) = struct('name',PlayerBlack,'games',GameNum+IndexSymmetry);
							end
							BlackInd = length(Players);
						end
						Labels(GameNum+IndexSymmetry) = BlackInd;
						WhiteInd = [];
						for p=1:length(Players)
							if strcmpi(PlayerWhite,Players(p).name)
								WhiteInd = p;
								Players(p).games = [Players(p).games GameNum+8+IndexSymmetry];
								break;
							end
						end
						if isempty(WhiteInd)
							Players(end+1) = struct('name',PlayerWhite,'games',GameNum+8+IndexSymmetry);
							WhiteInd = length(Players);
						end
						Labels(GameNum+8+IndexSymmetry) = WhiteInd;
					end
				end
				GameNum			= GameNum + 16;
			end
		end
	end
end
Lall = Labels;
GameNum = GameNum-16;
return;


MINGAMES = 30;
RemoveGames = [];
for p=1:length(Players)
	if length(Players(p).games) < MINGAMES
		RemoveGames = [RemoveGames, Players(p).games];
	end
	if length(Players(p).games) > 100
		RemoveGames = [RemoveGames, Players(p).games(101:end)];
	end
end
Labels = Lall;
Labels(RemoveGames) = [];

for KERNELtype = 1:3
	for MAXLENGTH = 1:length(MAXLENGTHparams)
		for DescriptorType = 1:3
			d = [];
			for g = 1:2:GameNum
				if toc > 2
					disp(g); tic;
				end
				coords = AllCoords(i).coords;
				if isempty(d)
					d	= reshape(GoBoardDescriptor(coords,1,DescriptorType,MAXLENGTHparams(MAXLENGTH)),[],1);	% Black
					d(:,GameNum) = zeros(size(d));
				else
					d(:,g)	= reshape(GoBoardDescriptor(coords,1,DescriptorType,MAXLENGTHparams(MAXLENGTH)),[],1);	% Black
				end
				d(:,g+1)	= reshape(GoBoardDescriptor(coords,2,DescriptorType,MAXLENGTHparams(MAXLENGTH)),[],1);	% White
			end
			d=d';

			% TO DO: update all other Players.game entries (they'll be wrong after this)
			dall=d;
			d(RemoveGames,:) = [];

			% Scale;
			d = scale01(d);
			d = sparse(d);

			for i = 1:10
				p			= randperm(size(d,1));
				Cutoff		= ceil(size(d,1)*7/10);
				TrainIndices= p(1:Cutoff);
				TestIndices	= p(Cutoff+1:end);


				TrainData	= d(TrainIndices,:);
				TrainLabels	= Labels(TrainIndices)';
				TestData	= d(TestIndices,:);
				TestLabels	= Labels(TestIndices)';
				TestLabelsR	= ceil(rand(size(TestLabels)) * max(Labels));

				% 			K=3;
				% 			nnidx = annquery(full(TrainData'), full(TestData'), K)';
				% 			correct = any(nnidx == repmat(TestLabels,1,size(nnidx,2)),2);
				% 			fprintf('chance is %f, nearest neighbor is %f with %d unique ones\n', ...
				% 				10*1/length(unique(TestLabels)), 10*correct/length(TestLabels), length(unique(nnidx)))

				SVMtype		= 0;	% 0=C, 1=Nu
				%			KERNELtype	= 1;	% 1=polynomial
				KERNELDegree= 3;	% default 3
				model		= svmtrain(TrainLabels, TrainData,sprintf('-s %d -t %d -d %d',SVMtype,KERNELtype,KERNELDegree));
				%			predictions1= svmpredict(TrainLabels,TrainData,model);
				predictions2= svmpredict(TestLabels,TestData,model);

				accuracyNN(i)=nnz(correct)/length(TestLabels);
				accuracy(i) = nnz(predictions2 == TestLabels)/length(TestLabels);
			end
			Ma(DescriptorType, MAXLENGTH) = mean(accuracy);
			Sa(DescriptorType, MAXLENGTH) = std(accuracy);
			Num(DescriptorType, MAXLENGTH) = length(unique(predictions2));

%			NN(DescriptorType, MAXLENGTH) = mean(accuracyNN);
			disp([Ma*100  Num])

		end
	end
	beep
end

% function Player = switchPlayer(Player)
% Player = 3 - Player;
% return;

% for p=1:length(Players)
% 	L(p)=length(Players(p).games);
% end
% for i=1:max(L)
% 	atleast(i) = nnz(L>=i);
% end
% hist(L);
