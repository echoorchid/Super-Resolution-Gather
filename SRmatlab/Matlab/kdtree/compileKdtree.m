filelist = dir('*.cpp');
for i=1:length(filelist)
    filename = [filelist(i).name(1:end-3) mexext];
    if exist(filename,'file')~=3
        mex(filelist(i).name);
    end
end