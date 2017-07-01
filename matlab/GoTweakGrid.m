function pts = GoTweakGrid(pts, Spacing, E1, E2)
[M,N] = size(E1);
for Repeat = 1:2
	for Index = 1:4
		for Direction = 1:2
% 			bw  = GoDrawGridLines(pts,[M N],Spacing);
% 			figure(2); clf; imagesc(cat(3,E1,E2,bw)); title(sprintf('Repeat=%i, Point=%i',Repeat, Index))
% 			hold on;
% 			for i = 1:4
% 				text(pts(2,i),pts(1,i),int2str(i),'Color','w');
% 			end
% 			pause(.1);
			pts = TweakOnePt(pts, Spacing, E1, E2, Index, Direction);
		end
	end
end
return;


function pts = TweakOnePt(pts, Spacing, E1, E2, Index, Direction)
[M,N] = size(E1);

d=zeros(4);
for i=1:4
	for j=i+1:4
		d(i,j) = norm(pts(:,i) - pts(:,j));
	end
end

Distance = min(d(d~=0)) / min(Spacing) / 16;
Steps = 8;
offsets = -Distance:(Distance/Steps*2):Distance;

score = zeros(length(offsets));
for i=1:length(offsets)
	NewPts			= pts;
	NewPts(Direction,Index) = NewPts(Direction,Index) + offsets(i);
	bw1				= GoDrawGridLines(NewPts,[M N],[Spacing(1) NaN]);
	bw2				= GoDrawGridLines(NewPts,[M N],[NaN Spacing(2)]);
	score(i)		= (nnz(bw1 & E1) + nnz(bw2 & E2));
end


% score = scale01(score);
% im = double(E1|E2);
% for i=1:length(offsets)
% 	for j=1:length(offsets)
% 		NewPt			= round(pts(:,Index)  + [offsets(i); offsets(j)]);
% 		im(NewPt(1),NewPt(2)) = score(i,j);
% 	end
% end
% figure(2); clf; imagesc(im); colorbar

%[i,j] = find(score == max(score(:)),1,'first');
[val,i] = max(score(:));
pts(Direction,Index) = pts(Direction,Index) + offsets(i);
return;