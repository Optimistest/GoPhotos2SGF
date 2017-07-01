function Lines = GoGrowGrid4(Lines,Spacing,im,Stones,E1,E2)
[M,N,channels] = size(im);
if nargin < 2
	Spacing = [1 1];
end
if nargin < 4
	Stones = false([M N]);
end
if nargin < 6
	E1 = EdgeAngle(im,mean([Lines(:,1).theta])) & ~Stones;
	E2 = EdgeAngle(im,mean([Lines(:,2).theta])) & ~Stones;
end

while any(Spacing < 18)
	[Lines,Spacing] = GrowGridOnce(Lines,Spacing,E1,E2);
%	set(1,'Name',int2str(Spacing)); pause(.1);
%	pts = GoTweakGrid(pts, Spacing, E1, E2);
end
return;

function [Lines,Spacing] = GrowGridOnce(Lines,Spacing,E1,E2);

pts=[];
for i = 1:2
	A = Lines(i,1).p(1);		% Line from Group 1
	B = Lines(i,1).p(2);
	for j=1:2
		a = Lines(j,2).p(1);	% Line from Group 2
		b = Lines(j,2).p(2);
		x = (b-B)/(A-a);		% Intersection
		y = (A*x+B + a*x+b)/2;
		pts(:,end+1) = [x y]';
	end
end


[M,N] = size(E1);
% put points in counter-clockwise ordering
middle = mean(mean(pts,3),2);
angle = zeros(1,4);
for i = 1:size(pts,2)
	vector = pts(:,i) - middle;
	angle(i)	= atan2(vector(2),vector(1)) * 180/pi;
end
[val,index] = sort(angle,'ascend');
pts = pts(:,index);
%pts = pts([2 1],:);

% Make box with counter-clockwise ordering
scale = min([M N]);
x = scale*(.25 + .5*  [ 0 0 1 1]*Spacing(1));	% Top-Left, Bot-Left, Bot-Right, Top-Right
y = scale*(.25 + .5*  [ 0 1 1 0]*Spacing(2));

% Find Transformation
T = cp2tform(pts',[x' y'],'projective');
[xT,yT] = tformfwd(T,pts(1,:),pts(2,:));

% For each direction
TL = [xT(1), yT(1)]';
BL = [xT(2), yT(2)]';
BR = [xT(3), yT(3)]';
TR = [xT(4), yT(4)]';

%bwBOX = GoDrawGridLines(flipud(pts),[M N],[1 1]);
bwBOX = GoDrawGridLines(pts,[M N],[1 1]);
[Xcenter,Ycenter]=find(bwBOX);
bwBOXfull = imfill(bwBOX,ceil([mean(Xcenter),mean(Ycenter)]));
se = strel('disk',4);
bwBOXfull = imdilate(bwBOXfull,se);

%figure(1);clf;
score = -inf*ones(2,2);
for g = 1:2
	if Spacing(g) < 18
		for BothSides = 1:2
			[bw1,bw2] = drawline(g,BothSides,Spacing,T,TL,BL,BR,TR,bwBOXfull,E1,E2,se);
			score(g,BothSides) = (nnz(bw1 & E1) + nnz(bw2 & E2));

% 			NewPoints(:,:,g,BothSides) = [xTi; yTi];
			if 1
				figure(1); subplot(2,2,sub2ind([2 2],g,BothSides));
				imagesc(cat(3,E1|E2,bw1|bw2,bwBOXfull)); axis off; axis image;
				title(sprintf('group=%i, side=%i,score=%f',g,BothSides,score(g,BothSides))); 
			elseif 0
				folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\photos\results';
				imwrite(cat(3,E1|E2,bw1|bw2,bwBOXfull),fullfile(folder,sprintf('GrowGrid_%i_%i_%i.jpg',g,Spacing(g),BothSides)));
			end		
		end
	end
end
pause(1);
[Group,Side] = find(score==max(score(:)),1,'first');
%pts = NewPoints(:,:,Group,Side);
[bw1,bw2] = drawline(Group,Side,Spacing,T,TL,BL,BR,TR,bwBOXfull,E1,E2,se);
[bw1Next,bw2Next] = drawline(Group,Side,Spacing,T,TL,BL,BR,TR,bwBOXfull,E1,E2, se,2);
Spacing(Group) = Spacing(Group) + 1;
if Group==1
	d			= bwdist(bw1);
	LineWidth	= ceil(max(4,min(min(d(bw1Next)))/4));
	bw1			= imdilate(bwareaopen(bw1,10,8),strel('disk',LineWidth));
	[x,y]		= find(bw1 & E1);
else
	d			= bwdist(bw2);
	LineWidth	= ceil(max(4,min(min(d(bw2Next)))/4));
	bw2			= imdilate(bwareaopen(bw2,10,8),strel('disk',LineWidth));
	[x,y]		= find(bw2 & E2);
end


p = polyfit(x,y,  1);
%p = polyfit(NewLinePts{Group,Side}(1,:),NewLinePts{Group,Side}(2,:),  1)
p = reshape(p,1,1,2);

pIN = zeros(2,2,2);
for g=1:2
	for s = 1:2
		pIN(g,s,:) = reshape(Lines(g,s).p,1,1,2);
	end
end
% Figure out which angle (1st coefficent of p)
[tmp,ind] = sort(abs(reshape(pIN(:,:,1),1,[]) - p(1)));
[g,s] = ind2sub([2 2],ind(1:2));
% Figure out which of the 2 lines at that angle
TwoLinesRho(1,1) = pIN(g(1),s(1),2);
TwoLinesRho(1,2) = pIN(g(2),s(2),2);
[tmp,TwoLinesInd] = min(abs(TwoLinesRho-p(2)));
replaceG			= g(TwoLinesInd);
replaceS			= s(TwoLinesInd);

Lines(replaceG,replaceS) = struct('theta',[],'rho',[],'p',reshape(p,1,2));

return;


function [bw1,bw2] = drawline(g,BothSides,Spacing,T,TL,BL,BR,TR,bwBOXfull,E1,E2,se,StepNumber)
[M,N] = size(E1);
if nargin < 13
	StepNumber = 1;
end
if g==1
	Start(:,1)=BL; Stop(:,1) = TL;
	Start(:,2)=BR; Stop(:,2) = TR;
else
	Start(:,1)=BL; Stop(:,1) = BR;
	Start(:,2)=TL; Stop(:,2) = TR;
end
if BothSides == 1
	tmp		= Start;
	Start	= Stop;
	Stop	= tmp;
end
ThisSpacing		= Spacing;
ThisSpacing(g)	= ThisSpacing(g) + StepNumber;
Stop			= Start + (Stop-Start)*ThisSpacing(g)/Spacing(g);
[xTi,yTi]		= tforminv(T,[Start(1,:) Stop(1,:)],[Start(2,:) Stop(2,:)]);
bw1				= GoDrawGridLines([xTi; yTi],[M N],[ThisSpacing(1) NaN])  & ~bwBOXfull;
bw1				= imdilate(  bwareaopen(bw1,5,8), se);
bw2				= GoDrawGridLines([xTi; yTi],[M N],[NaN ThisSpacing(2)])  & ~bwBOXfull;
bw2				= imdilate(  bwareaopen(bw2,5,8), se);
return;
