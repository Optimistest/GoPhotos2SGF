function string = estimate_time_remaining(i,N)
t = toc;
est = (t/i)*N - t;
hour= floor(est/60^2);
min = floor([est-(hour*60^2)]/60);
sec = floor(mod(est,60));

string = int2str(sec);
if sec < 10
	string = [' ' string];
end
if min > 0
	string = [int2str(min) ':' string];
	if min < 10
		string = [' ' string];
	end
end
if hour>0
	string = [int2str(hour) ':' string];
	if hour< 10
		string = [' ' string];
	end
end
