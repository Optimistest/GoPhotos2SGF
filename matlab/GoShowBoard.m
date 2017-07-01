function GoShowBoard(board)
if nargin == 0
	board = zeros(19);
end
[M,N] = size(board);
rectangle('Position', [.5 .5 M N],'Curvature',[0 0],'FaceColor',hex2dec(['85'; '5E'; '42'])/255);
axis equal; axis([0 20 0 20]); 
for L = 1:M
	line([L L],[1 N],'Color','k');
end
for L = 1:N
	line([1 M],[L L],'Color','k');
end
for r=[4 10 16]
	for c = [4 10 16]
		rectangle('Position',[[r c]-.05, .1,.1],'Curvature',[1 1],'FaceColor','k');
	end
end

for r = 1:M
	for c = 1:N
		if board(r,c) == 1
			rectangle('Position',[[r c]-.5, 1,1],'Curvature',[1 1],'FaceColor','k');
		elseif board(r,c) == 2
			rectangle('Position',[[r c]-.5, 1,1],'Curvature',[1 1],'FaceColor','w');
		end
	end
end
set(gca,'xtick',[1 4 10 16 19]);
set(gca,'ytick',[1 4 10 16 19]);
return;