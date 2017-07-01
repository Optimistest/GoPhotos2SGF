function bw = GoDrawGridLines(L,imORimsize,Spacing)
if nargin < 3
	Spacing = [18 18];
end
% first argument is either 4 lines or 4 points
if any(numel(imORimsize) == [2 3])
	M = imORimsize(1);
	N = imORimsize(2);
else
	[M,N,tmp] = size(imORimsize);
end

if isstruct(L)
	% Find 4 corner points
	pts=[];
	for i = 1:2
		A = L(i,1).p(1);		% Line from Group 1
		B = L(i,1).p(2);
		for j=1:2
			a = L(j,2).p(1);	% Line from Group 2
			b = L(j,2).p(2);
			x = (b-B)/(A-a);		% Intersection
			y = (A*x+B + a*x+b)/2;
			pts(:,end+1) = [x y]';
		end
	end
else
	pts = L;
end
% put points in counter-clockwise ordering
middle = mean(mean(pts,3),2);
angle = zeros(1,4);
for i = 1:size(pts,2)
	vector = pts(:,i) - middle;
	angle(i)	= atan2(vector(2),vector(1)) * 180/pi;
end
[val,index] = sort(angle,'ascend');
pts = pts(:,index);
pts = pts([2 1],:);

% Make box with counter-clockwise ordering
scale = min([M N]);
x = scale*(.25 + .5*  [ 0 0 1 1]);	% Top-Left, Bot-Left, Bot-Right, Top-Right
y = scale*(.25 + .5*  [ 0 1 1 0]);

% Find Transformation
T = cp2tform(pts',[x' y'],'projective');
[xT,yT] = tformfwd(T,pts(1,:),pts(2,:));

% For each direction
TL = [xT(1), yT(1)]';
BL = [xT(2), yT(2)]';
BR = [xT(3), yT(3)]';
TR = [xT(4), yT(4)]';
score=zeros(18,2,5);
%	figure(1);clf; imagesc(im);
bw = false([M N]);
for g = 1:2
	% Choose a spacing between the lines
	spacing = Spacing(g);
	if ~isnan(spacing)
		if g==1
			Start(:,1)=BL; Stop(:,1) = TL;
			Start(:,2)=BR; Stop(:,2) = TR;
		else
			Start(:,1)=BL; Stop(:,1) = BR;
			Start(:,2)=TL; Stop(:,2) = TR;
		end
		direction = mean(Stop-Start,2);
		angle = atan2(direction(2),direction(1))*180/pi;
		%figure(1);clf; imagesc(im);
		EndPoints=zeros(2,2);
		% Find the lines in the transformed space
		%		figure(2); clf; imagesc(im);
		for LineNum = 0:spacing
			for i=1:2
				EndPoints(:,i) = Start(:,i) + (Stop(:,i) - Start(:,i)) * LineNum / spacing;
			end
			[xTi,yTi] = tforminv(T,EndPoints(1,:),EndPoints(2,:));
% 			if LineNum==0 || (norm(mean(Stop-Start,2))-abs(diff([L(:,g).rho]))) < 3
% 				hold on;
% 				plot(xTi,yTi,'b-');
% 			end
			p = polyfit(yTi,xTi,1);
			p_inv = [1/p(1), -p(2)/p(1)];

			x1 = floor(min(yTi(:))):floor(max(yTi(:)));		%		x1 = 1:M
			y1 = floor(polyval(p,x1));
			y2 = floor(min(xTi(:))):floor(max(xTi(:)));		%		y2 = 1:N
			x2 = floor(polyval(p_inv,y2));
			xy = unique([x1 x2; y1 y2]','rows');
			x=xy(:,1); y=xy(:,2);
			inbounds = y>=1 & y<=N & x>=1 & x<=M;
			ind = sub2ind([M N],x(inbounds),y(inbounds));
			bw(ind)=1;
		end
	end
end
% colors = hsv(5);
% for j=1:2
% 	figure(j+1); clf;
% 	for i=[2 4 5]
% 		plot(5:18,scale01(score(5:end,j,i)*(-1)^(i==2)),'Color',colors(i,:));hold on;
% 	end
% end
% legend('2','4','5')

% figure(4); clf; plot(perplot(:,[6 12]));
% disp(' ')
