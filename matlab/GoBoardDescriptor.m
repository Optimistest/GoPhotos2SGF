function smallboard = GoBoardDescriptor(board)
black = board == 1;
white = board == 2;

black = imfilter(double(black),fspecial('gaussian',[5 5],2));
white = imfilter(double(white),fspecial('gaussian',[5 5],2));

black = imresize(black,[5 5],'bilinear');
white = imresize(white,[5 5],'bilinear');

smallboard = scale01(black - white);
return;
