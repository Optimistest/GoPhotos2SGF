function [T,pts,TL,BL,BR,TR] = FindHomography(Lines,im)
[M,N,channels] = size(im);
Spacing = [18 18];

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
T = cp2tform(flipud(pts)',[y' x'],'projective');
%T = cp2tform(pts',[x' y'],'projective');
pts = AdjustForStoneHeight(T,pts,im);
T = cp2tform(flipud(pts)',[y' x'],'projective');
[xT,yT] = tformfwd(T,pts(2,:),pts(1,:));

% For each direction
TL = [xT(1), yT(1)]';
BL = [xT(2), yT(2)]';
BR = [xT(3), yT(3)]';
TR = [xT(4), yT(4)]';

return;
