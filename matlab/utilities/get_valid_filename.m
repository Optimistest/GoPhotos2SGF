function valid_filename = get_valid_filename(folder, filename)
% GET_VALID_FILENAME: given a file .../FILENAME.EXT, returns e.g. .../FILENAME_3.EXT
% tries integers up to 999, then gives control to the keyboard
[folder2,file,ext] = fileparts(filename);
for i = 0:(10^3-1)
	if i==0
		valid_filename = filename;
	else
		valid_filename = sprintf('%s%s%s%s', file, '_',int2str(i),ext);
	end
	if ~exist(fullfile(folder, valid_filename))
		return
	end 
end
warning('No valid filename found.  Control at Keyboard');
keyboard;
return;  