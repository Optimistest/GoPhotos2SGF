function [Fmax,Fmin,im] = GoFindStoneFeatures2(hsv,Lines)
if nargin >= 2
	[M,N,channels] = size(hsv);

	[T,pts,TL,BL,BR,TR] = FindHomography(Lines,hsv(:,:,1));
	TL2 = TL + (TL-TR)/18/2 + (TL-BL)/18/2;
	BR2 = BR + (BR-TR)/18/2 + (BR-BL)/18/2;
	BL2 = BL + (BL-BR)/18/2 + (BL-TL)/18/2;
	TR2 = TR + (TR-TL)/18/2 + (TR-BR)/18/2;
	ptsT = [TL2 BL2 BR2 TR2];
	Xdata1 = [min(ptsT(2,:)) max(ptsT(2,:))];
	Ydata1 = [min(ptsT(1,:)) max(ptsT(1,:))];
	Udata = [1 N];
	Vdata = [1 M];

	NewSize = min(M,N)/2*[1 1]/4;
	[hsv, Xdata,Ydata] = imtransform(hsv,     T,'nearest','Size',NewSize, 'UData',Udata ,'VData',Vdata ,'Xdata',Xdata1,'Ydata',Ydata1);
end
Radius		= ceil(min(size(hsv))/19 * .9  /2);
EdgeDetectSize = 0; % default .1 to .4
smalldisc = padarray(fspecial('disk', Radius), ceil(Radius*EdgeDetectSize)*[1 1],0,'both');
bigdisc   =          fspecial('disk', Radius + ceil(Radius*EdgeDetectSize));
discfilter = zeros(size(bigdisc));
discfilter(smalldisc~=0) = 1/nnz(smalldisc);
if EdgeDetectSize > 0
	discfilter(bigdisc & ~smalldisc) = -1/nnz(bigdisc & ~smalldisc );
end
%discfilter = discfilter - mean(discfilter(:));
score1 = imfilter(im2double(hsv), discfilter,'replicate');
scoreSD = stdfilt(im2double(hsv), fspecial('disk', Radius/2)>0);
score1 = cat(3,score1,scoreSD);

[M,N,channels] = size(score1);
[X,Y] = meshgrid(1:M,1:N);
for i=0:18
	for j=0:18
		x = M/19/2 + M/19*i;
		y = N/19/2 + M/19*j;
		mask = ( (X-x).^2 + (Y-y).^2 )  < Radius.^2;
		for c=1:channels
			s = score1(:,:,c);
			filtvals = s(mask);
			Fmin(i+1,j+1,1,c) = min(filtvals);
			Fmax(i+1,j+1,1,c) = max(filtvals);
		end
	end
end

if nargout == 0
	figure(1); clf;
	s(1)=subplot(1,2,1); imagesc(score1); axis image; axis off; colorbar; colormap hot;							title('filtering result')
	s(2)=subplot(1,2,2); imagesc(xlim(s(1)),ylim(s(1)),im); axis image; axis off;								title('rectified image')
	linkaxes(s);
end
return;
