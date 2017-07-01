function BW = EdgeAngle(im,Peak)
im = im2double(im);
% Detect New Edges at Appropriate Angles
ExpectedLineWidth = 2;
LineWidths = ceil((.5:.2:1.5)*ExpectedLineWidth);
LineWidths = 2:4;
MaxResponse = zeros(size(im));
for p=1:length(Peak)
	for i=1:length(LineWidths)
		stripe	= ones(LineWidths(i)*5*4,LineWidths(i)*4);
		hat		= [0*stripe 0*stripe 1*stripe 0*stripe 0*stripe];

		TiltedHat	= imrotate(hat,-Peak(p),'bicubic'); 
		TiltedHat	= imresize(TiltedHat,1/4);
		TiltedHat	= imcrop([0 1],[0 1], TiltedHat,[.25 .25 .5 .5]);
%		TiltedHat	= imcrop(TiltedHat,LineWidths(i)*[1 1 3 3]);
		TiltedHat	= TiltedHat - mean(TiltedHat(:));
		TiltedHat	= TiltedHat / sum(abs(TiltedHat(:)));
		if i==1 && p==1
			MaxResponse	= imfilter(im,TiltedHat);
		else
			MaxResponse	= min(MaxResponse,imfilter(im,TiltedHat));
		end
	end
end
tmp = imcrop([0 1], [0 1], MaxResponse, [.25 .25 .75 .75]);
p  = prctile(tmp(:),5);
BW = MaxResponse < p;
return;
