function distance = DistancePointToLine(points, LinePoint1, LinePoint2)
LineJ1toJ2	= (LinePoint2 - LinePoint1);
direction	= [-LineJ1toJ2(2) LineJ1toJ2(1)];
direction	= direction / norm(direction);

distance = inf;
for i = 1:size(points,1)
	LineJ1toI1	= (points(i,:) - LinePoint1);
	if norm(LineJ1toI1) < eps
		distance = 0;
	else
		DistPointI1ToLineJ		= abs(norm(LineJ1toI1) * dot(LineJ1toI1/norm(LineJ1toI1), direction));
		distance = min(distance, DistPointI1ToLineJ);
	end
end
