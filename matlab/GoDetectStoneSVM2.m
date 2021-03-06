function [scores,scores1] = GoDetectStoneSVM2(hsv, svm3In)
persistent svm3 MinFiltVals MaxFiltVals
if isempty(svm3)
	load StoneSVM3.mat svm3 MinFiltVals MaxFiltVals
end
if nargin >= 2,	svm3 = svm3In;,	end

NumFeatures =  size(svm3.SVs,2);
[M,N,channels] = size(hsv);
if NumFeatures == 2
	hsv = hsv(:,:,2:3);
end
Radius		= ceil(min([M N])/19 * .9  /2);
EdgeDetectSize = 0;
smalldisc = padarray(fspecial('disk', Radius*.8), ceil(Radius*EdgeDetectSize)*[1 1],0,'both');
bigdisc   =          fspecial('disk', Radius*.8 + ceil(Radius*EdgeDetectSize));
discfilter = zeros(size(bigdisc));
discfilter(smalldisc~=0) = 1/nnz(smalldisc);
score1 = imfilter(im2double(hsv), discfilter,'symmetric');
if NumFeatures > 3
	score1 = cat(3,score1,stdfilt(im2double(hsv), fspecial('disk', Radius/2)>0));
end
features = reshape(score1,[],size(score1,3));
features = (features - repmat(MinFiltVals'				 ,size(features,1),1)) ...
					./ repmat(MaxFiltVals' - MinFiltVals',size(features,1),1);

%[predict,accuracy,probs]		= svmpredict(ones(size(features,1),1), features, svm3,'-b 1');
[predict,accuracy,probs]		= svmpredict(ones(size(features,1),1), features, svm3,'-b 1');

pEmpty = reshape(probs(:,1),M,N);
pBlack = reshape(probs(:,2),M,N);
pWhite = reshape(probs(:,3),M,N);

figure(1); clf;
subplot(2,2,1); imagesc(pEmpty); axis image; colorbar; title('pEmpty'); axis off; 
subplot(2,2,2); imagesc(pBlack); axis image; colorbar; title('pBlack'); axis off; 
subplot(2,2,3); imagesc(pWhite); axis image; colorbar; title('pWhite'); axis off; 
subplot(2,2,4); imagesc(hsv(:,:,end));    axis image; colorbar; title('image');axis off; 

% [M,N,channels] = size(score1);
% [X,Y] = meshgrid(1:M,1:N);
% p=zeros(19,19,3);
% for i=0:18
% 	for j=0:18
% 		x = M/19/2 + M/19*i;
% 		y = N/19/2 + N/19*j;
% 		mask = ( (X-x).^2 + (Y-y).^2 )  < (Radius/2).^2;
% 		[MaxBlack, indBlack] = max(pBlack(mask));
% 		p(i+1,j+1,1) = prctile(pBlack(mask),95);
% 		p(i+1,j+1,2) = prctile(pWhite(mask),95);
% 	end
% end
% figure(2); clf;
% subplot(2,2,1); imagesc(p(:,:,3)'); axis image; colorbar; title('pEmpty');
% subplot(2,2,2); imagesc(p(:,:,1)'); axis image; colorbar; title('pBlack');
% subplot(2,2,3); imagesc(p(:,:,2)'); axis image; colorbar; title('pWhite')
% subplot(2,2,4); imagesc(hsv(:,:,end));    axis image; colorbar; title('image');
% 
% return;

[M,N,channels] = size(score1);
[X,Y] = meshgrid(1:M,1:N);
allmasks=false(size(X));
for i=0:18
	for j=0:18
		x = M/19/2 + M/19*i;
		y = N/19/2 + M/19*j;
		allmasks = allmasks | (X-x).^2 + (Y-y).^2 < (Radius*.8).^2;
	end
end
NotAnyMask = ~allmasks;
pBlack(NotAnyMask) = NaN;
pWhite(NotAnyMask) = NaN;

scores = zeros(19,19,2);
scores1 = zeros(19,19);
[Xi,Yi] = ndgrid(1:19,1:19);
X = (Xi-.5)/19*M;
Y = (Yi-.5)/19*N;
XY		= round([X(:) Y(:)]);
Xi=Xi(:);
Yi=Yi(:);
[X,Y] = ndgrid(1:M,1:N);
count = 0;
while any(scores(:)==0) && (  any(abs(pBlack(:))>.5)  || any(abs(pWhite(:))>.3)  )
	count=count+1;
	disp(count);
	figure(2); clf;
	subplot(2,2,1); imagesc(hsv(:,:,2));	 axis image; axis off; colorbar;
	subplot(2,2,2); imagesc(pBlack); axis image; axis off; colorbar;
	subplot(2,2,3); imagesc(pWhite); axis image; axis off; colorbar;
	subplot(2,2,4); imagesc(scores1); axis image; axis off; colorbar;
	pause(.01);
% 	[valB,indB]			= max(pBlack(:));
% 	[valW,indW]			= max(pWhite(:));
	
	% Find Best Stone, counting only 90th percentile rather than absolute max
	[M,N,channels] = size(score1);
	[X,Y] = meshgrid(1:M,1:N);
	p=zeros(19,19,3);
	for i=0:18
		for j=0:18
			x = M/19/2 + M/19*i;
			y = N/19/2 + N/19*j;
			mask = ( (X-x).^2 + (Y-y).^2 )  < (Radius*.8).^2;
			p(i+1,j+1,1) = prctile(pBlack(mask),90);
			p(i+1,j+1,2) = prctile(pWhite(mask),90);
		end
	end
	[val,ind1] = max(p(:));
	% Now Find the max (center) of that stone
	[i,j,bw] = ind2sub([19 19 2], ind1);
	i=i-1; j=j-1;
	x = M/19/2 + M/19*i;
	y = N/19/2 + N/19*j;
	mask = ( (X-x).^2 + (Y-y).^2 )  < (Radius*.8).^2;
	if bw==1
		tmp = pBlack;
		tmp(~mask) = NaN;
		[val2,ind] = max(tmp(:));
	else
		tmp = pWhite;
		tmp(~mask) = NaN;
		[val2,ind] = max(tmp(:));
	end
%	figure(3); subplot(1,2,1); imagesc(mask); axis image; title('mask 1');
	
	if isnan(val) || val < .3
		break;
	else
		[x,y]				= ind2sub([M N],ind);
		distances			= sum((repmat([x y],19*19,1) - XY).^2,2);
		[tmp,closest]		= min(distances);
		scores(Xi(closest),Yi(closest),1)	= pBlack(ind);
		scores(Xi(closest),Yi(closest),2)	= pWhite(ind);
		if bw==1
			scores1(Xi(closest),Yi(closest))	= -val;
		else
			scores1(Xi(closest),Yi(closest))	= val;
		end
		mask				= (((X-x).^2 + (Y-y).^2)) < (1.2*Radius)^2;
		mask = mask';
%		figure(3); subplot(1,2,2); imagesc(mask); axis image; title('mask 2');
		pBlack(mask)		= NaN;
		pWhite(mask)		= NaN;
	end
end
