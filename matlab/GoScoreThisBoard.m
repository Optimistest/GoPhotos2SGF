function score = GoScoreThisBoard(probs,board)
warnstate = warning('Query','MATLAB:log:logOfZero');
			warning('Off','MATLAB:log:logOfZero');
score = 0;
Pblack = probs(:,:,1);		score = score + sum(log2(eps+Pblack(board==1)));
Pwhite = probs(:,:,2);		score = score + sum(log2(eps+Pwhite(board==2)));
Pempty = 1-(Pblack+Pwhite);	score = score + sum(log2(eps+Pempty(board==0)));
			warning(warnstate.state,'MATLAB:log:logOfZero');
return;
