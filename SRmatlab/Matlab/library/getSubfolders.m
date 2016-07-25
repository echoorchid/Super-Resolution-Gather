% function to get subfolders of a given folder
function folderlist = getSubfolders(srcpath)

foo = dir(srcpath);

folderlist = [];
for i=1:length(foo)
    % if the file is not a dir
    if foo(i).isdir == 0
        continue;
    end
    % if the file is . or ..
    if strcmpi(foo(i).name,'.') || strcmpi(foo(i).name,'..')
        continue;
    end
    folderlist(end+1).name = foo(i).name;
end
    