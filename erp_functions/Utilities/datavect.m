function data = datavect(data, RC)
% convert the data to one column
% this part is from DISTRIB package
% RC: 1, the output is one column
% RC: 2, the output is one row

nm =size(data);
if min(nm) > 1
   error('First argument must be a vector');
end
if  nm(RC) == 1 
	data = data';
end

end