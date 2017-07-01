function out = medianHSV(im)
[M,N,channels,NumImages] = size(im);
dists = zeros(M,N,NumImages);
for i=1:NumImages
	for j=1:NumImages
		if i~=j
			dists(:,:,i) = dists(:,:,i) + sum(abs(im(:,:,:,i) - im(:,:,:,j)),3);
		end
	end
end
[tmp,indices] = min(dists,[],3);
out = zeros(M,N,channels);
for i=1:NumImages
	chosenIm	= im(:,:,:,i);
	mask		= indices == i;
	for c=1:channels
		chan			= chosenIm(:,:,c);
		current			= out(:,:,c);
		current(mask)	= chan(mask);
		out(:,:,c)		= current;
	end
end

