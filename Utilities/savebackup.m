function savebackup(variable, filename, sheetname, dt)

if nargin < 4
    dt = datestr(now,'yymmddHH');
end

filename_xlsx = strcat(filename, '_', dt, '.xlsx');
filename_mat = strcat(filename, '_', dt, '.mat');

if ispc || ismac
    writetable(variable, filename_xlsx, 'Sheet', sheetname);
    save(filename_mat, 'variable', '-v7.3'); %, '-nocompression'
elseif isunix
    save(filename_mat, 'variable', '-v7.3'); %, '-nocompression'
else
    error('Platform not supported!')
end

end