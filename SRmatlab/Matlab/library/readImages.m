% function to read the info of images into a list
function filelist = readImages(srcpath)
if exist('srcpath','var')~=1
    srcpath = pwd;
end

formats = imformats;
filelist = [];
for i = 1:length(formats)
    for j=1:length(formats(i).ext)
        extname = ['*.' cell2mat(formats(i).ext(j))];
        foo = dir(fullfile(srcpath,extname));
        if ~isempty(foo)
            filelist = [filelist, foo];
        end
    end
end