function [h,Together] = montageCell(InCell)
warning('off','Images:imshow:magnificationMustBeFitForDockedFigure');
warning('off','Images:initSize:adjustingMag');
Frames = prod(size(InCell));
for i=1:Frames
	[m(i),n(i),channels(i)] = size(InCell{i});
	if isfloat(InCell{i})
		InCell{i} = InCell{i}/max(InCell{i}(:));
	end
end
M=max(m); N=max(n); CHANNELS=max(channels);
if CHANNELS == 1 || CHANNELS == 3
	if islogical(InCell{1})
		c = 'uint8';
	else
		c = class(InCell{1});
	end
	if isfloat(InCell{1})
		MinVal =  Inf;
		for i=1:Frames
			MinVal = min(MinVal, min(InCell{i}(:)));
		end
		if MinVal < 0
			for i=1:Frames
				InCell{i} = InCell{i} - MinVal;
			end
		end
		MaxVal = -Inf;
		for i=1:Frames
			MaxVal = max(MaxVal, min(InCell{i}(:)));
		end
		if MaxVal > 1
			for i=1:Frames
				InCell{i} = InCell{i} ./ MaxVal;
			end
		end
	end
	Together = zeros(M,N,CHANNELS,Frames,c);
	for i=1:Frames
		[m,n,channels] = size(InCell{i});
		if channels == CHANNELS
			try
				Together(1:m,1:n,:,i) = InCell{i};
			catch
				keyboard;
			end
		elseif channels == 1
			Together(1:m,1:n,:,i) = repmat(InCell{i}, [1 1 CHANNELS]);
		else
			error('Inputs must have equal # of channels or 1 channel');
		end
		if islogical(InCell{i})
			Together(1:m,1:n,:,i) = Together(1:m,1:n,:,i)*255;
		end
	end
	h = montage(Together);
elseif all(channels==CHANNELS)
	for c=1:CHANNELS
		for i=1:Frames
			smaller{i} = InCell{i}(:,:,c);
		end
		figure(c);
		montageCell(smaller);
	end
end
set(gca,'Position',[0 0 1 1]);
set(gcf,'Color',0*[1 1 1]);
return;