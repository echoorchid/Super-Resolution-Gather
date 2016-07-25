% function to convert a number to a digit
function str=num2digits(x,ndigits)
if exist('ndigits')~=1
    ndigits=3;
end

str=num2str(x);

if length(str)<ndigits
    for i=1:ndigits-length(str)
        str=['0' str];
    end
end