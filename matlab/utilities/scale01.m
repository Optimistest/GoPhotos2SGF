function x = scale01(x)
if any(isinf(x(:)))  || all(isnan(x(:))) || min(x(:)) == max(x(:))
	return;
elseif issparse(x)	% if sparse, ignore zeros
	ind = find(x);
	x(ind) = x(ind) - min(x(ind));
	x(ind) = x(ind) / max(x(ind));
else
	x = x-min(x(:));
	x = x/max(x(:));
end