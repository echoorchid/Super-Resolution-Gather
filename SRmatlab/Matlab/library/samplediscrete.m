% function to sample from discrete density distribution
function y=samplediscrete(f)
f=f/sum(f);
Pr2=cumsum(f);
Pr1=Pr2;Pr1(2:end)=Pr1(1:end-1);Pr1(1)=0;
x=rand;
y=find(Pr2>=x & x>Pr1);
