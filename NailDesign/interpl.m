x = 0:pi/4:2*pi; 
v = sin(x);

xq = 0:pi/16:2*pi;
figure
vq1 = interp1(x,v,xq);
plot(x,v,'o',xq,vq1,':.');
xlim([0 2*pi]);
title('(Default) Linear Interpolation');

%% isnan try
A = 0./[-1 -2 0 2 1];
IsBroken = zeros(1,5);
if isnan(A)
   IsBroken(1) = 1;
   cons = 1;
   error('');

else
    cons = 0;
end