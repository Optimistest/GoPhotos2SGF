function NewPts = AdjustForStoneHeight(T,pts,im);
[M,N]			= size(im);
[xT,yT]			= tformfwd(T,pts(2,:),pts(1,:));
BoardSizeT		= mean(sqrt(sum(diff([xT([1 2 3 4 1]); yT([1 2 3 4 1])],2).^2,1)));

camera_height	= 3;
min_dist		= 3;
board_size		= 2;
stone_diameter	= board_size/19*.9;
stone_height	= stone_diameter / 4;

vertical		= M-pts(1,:);
closestPt		= min(vertical);
furthestPt		= max(vertical);
distances		= min_dist + board_size * (vertical-closestPt)/(furthestPt-closestPt);
offsets			= stone_height * (distances/camera_height) * BoardSizeT / board_size;

% Find intersection on board in rectified domain
%figure(1); clf; imagesc(im); hold on; plot(pts(2,:),pts(1,:),'g.'); axis image;
t = 0:.01:2*pi;
NewPts = pts;
for i = 1:length(xT)
	% Make circe in rectified domain
	x			= xT(i) + cos(t)*offsets(i);
	y			= yT(i) + sin(t)*offsets(i);
	% transform circle back to image domain
	[xTi,yTi]	= tforminv(T,x,y);
%	plot(xTi,yTi);
%	text(pts(2,i),pts(1,i),int2str(i));
	% Find points on the line
	choices		= find(abs(xTi - pts(2,i)) < 1);
	NewPts(1,i)	= min(yTi(choices));
end
%plot(NewPts(2,:),NewPts(1,:),'*r')
return;
