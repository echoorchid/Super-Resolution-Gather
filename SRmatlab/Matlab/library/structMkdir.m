% function to make dir for all the fiends in a structure
function structMkdir(s)

names = fieldnames(s);

for i=1:length(names)
    f = getfield(s,cell2mat(names(i)));
    if isa(f,'char')
        if exist(f,'dir')~=7
            mkdir(f);
        end
    end
end
