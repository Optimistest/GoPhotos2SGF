ResultFolder = 'C:\Users\Steve\Documents\classes\cs 290b fall 2007\Project Web Page\figures';
topfolder = 'C:\Users\Steve\Documents\matlab\go\photos\ken 4-3-2008';
Folders = dir(topfolder);
for FolderNum = length(Folders):-1:1
	if ~Folders(FolderNum).isdir ...
	||	Folders(FolderNum).name(1)=='.' ...
	|| ~exist(fullfile(topfolder, Folders(FolderNum).name,'MoveSequence.mat'),'file')
		Folders(FolderNum)=[];
	end
end
disp({Folders.name})

fig = 1;
N = 19*40;
for FolderNum = 2%1:length(Folders)
	folder = fullfile(topfolder, Folders(FolderNum).name);
	% Results Figures: Sequence of Original and Cartoon
	load(fullfile(folder, 'MoveSequence.mat'), 'boardlist');
	load(fullfile(folder, 'probs2.mat'), 'probs');
	probs = repmat(reshape(uint8(scale01(probs)*255), 19,19,1,[]), [1 1 3]);
	d = dir(fullfile(folder, '*.jpg'));
	inds = 1:10:min([length(d),size(boardlist,3), size(probs,4), 100]);
	ims = 255*ones(N,N,3,length(inds),'uint8');
	imBoards = ims;
	BigIm = 255*ones(N*3, N*length(inds),3,'uint8');
	for i = 1:length(inds)
		figure(fig); clf; GoShowBoard(boardlist(:,:,inds(i)));
		imBoards(:,:,:,i)	= flipdim(imrotate(imresize(frame2im(getframe(gca)), [N N]),90),2);
		im = imread(fullfile(folder, d(inds(i)).name));
		[m,n,c] = size(im);
		if m>n
			newM = N;	newN = ceil(N*n/m);
		else
			newN = N;	newM  = ceil(N*m/n);
		end
		im = imresize(im, [newM, newN]);
		ims(1:newM,1:newN,:,i)		 = im;
% 		subplot(1,2,1);		imagesc(im); axis image;		title(d(i).name);
% 		subplot(1,2,2);		GoShowBoard(boardlist(:,:,i));	title(int2str(i));
% 		pause(2);
		BigIm(    1:  N,1+(i-1)*N:i*N,:) = ims(:,:,:,i);
		BigIm(  N+1:2*N,1+(i-1)*N:i*N,:) = imresize(flipdim(probs(:,:,:,inds(i)),1), [N N],'nearest');
		BigIm(2*N+1:3*N,1+(i-1)*N:i*N,:) = imBoards(:,:,:,i);
		figure(fig+1); clf; imagesc(BigIm); axis image; axis off;
	end
	imwrite(BigIm, fullfile(ResultFolder , sprintf('PosterFigure1-%s.jpg', Folders(FolderNum).name)));

	% Original Photo
	
	% Hands Removed
	
	% Detected Edges & Lines
	
	% Ransac
	
	% GrowGrid?
	
	% Rectified
	
end
