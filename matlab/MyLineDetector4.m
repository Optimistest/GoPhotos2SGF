function [BW, LinesOut,im,Stones,rgb] = MyLineDetector3(rgbFull)
if nargin < 1
	folder = 'C:\Documents and Settings\sscher\My Documents\matlab\go\Ryan\data';
	%rgbFull = imread(fullfile(folder,'13112007030.jpg'));
	%rgbFull = imread(fullfile(folder,'13112007025.jpg'));
	%rgbFull = imread(fullfile(folder,'13112007022.jpg'));
	rgbFull = imread(fullfile(folder,'13112007043.jpg'));
	%rgbFull = imread('C:\Documents and Settings\sscher\My Documents\Research\recording go\Detecting Board\Go_board_Wikipedia.jpg');
	%rgbFull = imread('C:\Documents and Settings\sscher\My Documents\Research\manycam\two pics 001.jpg');
end
rgb		= imcrop([0 1],[0 1], rgbFull, [.25 .25 .5 .5]);
hsv		= rgb2hsv(rgb);
im		= hsv(:,:,3);
%im		= imfilter(im,fspecial('gaussian',[5 5], 2));
%im		= max(im(:)) - im;

ShowFigures = 1;

% Find Stones

% Find Initial Edges with LoG filter on Center-Cropped Image
BW = false(size(im));
for Sigma = 2:7
	BW = BW | edge(im,'log',[],Sigma);
end
%Stones = GoFilterStones(rgb);
Stones = false(size(im));
if ShowFigures
	figure(1); clf; imagesc(BW); title('detected edges');  pause(1);
	%figure(1); clf; imagesc(Stones); title('stones found with Saturated in HSV');  pause(1);
end
BW = BW & ~Stones;

% Find Initial Lines with Hough
[H, Theta, Rho] = hough(BW, 'ThetaResolution',1, 'RhoResolution',1);
Peaks = houghpeaks(H, 100, 'NHoodSize',floor(size(H)/(50*2)/2)*2+1);
Lines = houghlines(BW, Theta, Rho, Peaks);
Peak = FindDominantAngles(Lines);
if any(isnan(Peak) | isinf(Peak))
	disp('error with initial line detection');
	keyboard;
end
[tmp, ind] = sort(abs(Peak));
Peak = Peak(ind);
disp(sprintf('Dominant Directions are %i & %i',round(Peak(1)),round(Peak(2))));

 
rgb			= rgbFull;
%rgb		= imcrop([0 1],[0 1], rgbFull, [.1 .1 .8 .8]);
hsv			= rgb2hsv(rgb);
im			= hsv(:,:,3);
%Stones = GoFilterStones(rgb);
Stones = false(size(im));
for g = 1:2
	% Find edges at appropriate angle only
	BW = EdgeAngle(im,Peak(g));
	BW = BW & ~Stones;

	% Find Second Pass at Lines with Hough
	[H, Theta, Rho] = hough(BW, 'ThetaResolution',1, 'RhoResolution',1);
	Peaks = houghpeaks(H, 100, 'NHoodSize',floor(size(H)/(50*2)/2)*2+1);
	Lines = houghlines(BW, Theta, Rho, Peaks);
	if ShowFigures
		figure(1); clf; imagesc(BW); title('detected edges at dominant angle')
	end
	
	% Mark lines on image
	[M, N] = size(BW);
	for L=1:length(Lines)
		disp(L)
		direction = Lines(L).point2 - Lines(L).point1;
		direction = direction / norm(direction) * norm([M N]);
		BWLind{L} = [];
		t=-1:(.5/norm(direction)):1;
		
		for dilatex = -2:2
			for dilatey = -2:2
				p = repmat( [dilatex; dilatey] + floor(Lines(L).point1'),1,length(t)) + direction'*t;
				p = unique(round(p)','rows')';
				ind = all(p>= 1,1) & p(2,:)<=M & p(1,:)<=N;
				BWLind{L} = union(BWLind{L}, sub2ind([M N],p(2,ind),p(1,ind)));
			end
		end
	end

	% Find groups of the same line
	overlap = eye(length(Lines));
	for L=1:length(Lines)
		for K = L+1:length(Lines)
			overlap(L,K) = length(intersect(BWLind{L}, BWLind{K})) / ((length(BWLind{L}) + length(BWLind{K}))/2);
%			overlap(L,K) = nnz(BWLs(:,:,L) & BWLs(:,:,K)) / ((nnz(BWLs(:,:,L)) + nnz(BWLs(:,:,K)))/2);
		end
	end
	Same = overlap > .10;
	Same = max(Same,Same');
	for L=1:length(Lines)
		Same = Same*double(Same)~=0;
	end

	anchors = zeros(1,length(Lines));
	for L=1:length(Lines)
		for K = find(Same(L,:))
			if anchors(K)==0
				anchors(K)=L;
			end
		end
	end

	if ShowFigures
		figure(1);clf; imagesc(BW); colormap gray; axis image;
	end
	NewLines = struct([]);
	for A=unique(anchors)
		BWall = [];
		for L = find(anchors==A)
			BWall = [BWall BWLind{L}];
		end
		[Row,Col] = ind2sub([M N],BWall(BW(BWall)));
%		[Row,Col] = ind2sub([M N],BWall);
%		p = polyfit(Col,Row,1);
		p = polyfit(Row,Col,1);
		theta = atan2(-p(1),1)*180/pi;
		Yintercept = [0 p(2)];
		Xintercept = [-p(2)/p(1) 0];
		rho = DistancePointToLine([0 0],Xintercept, Yintercept);
		NewLines(end+1).theta = theta;
		NewLines(end).rho = rho;
		NewLines(end).p = p;
		if ShowFigures
			x = [1 M];
			y = polyval(p,x);
			hold on; plot(Col,Row,'b*');
%			hold on; plot(Row,Col,'g.');
			hold on; plot(y,x,'r-');
		end
	end
	if g==1
		SecondLines = NewLines;
	else
		SecondLines(end+1:end+length(NewLines)) = NewLines;
	end
end

% Divide into two groups of lines
dist = zeros(length(SecondLines),1);
for g=1:2
	dist(:,g) = abs([SecondLines.theta] - Peak(g));
end
[tmp, group] = min(dist,[],2);

LinesOut{1} = SecondLines(group==1);
LinesOut{2} = SecondLines(group==2);
return;

function Peak = FindDominantAngles(Lines)
angles = sin([Lines.theta]*pi/180);
warnstate = warning('off','stats:kmeans:EmptyCluster');
[idx, centers] = kmeans(angles(:),2,'start','sample','Replicates',100,'EmptyAction','singleton','Display','off');
warning(warnstate.state,'stats:kmeans:EmptyCluster');
Peak = asin(centers)*180/pi;
return;
