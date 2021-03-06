%% Constant
rho = 1.724e-6*(1+75*0.00393); %Ohm/cm
%%
% Design Loop
i = 6;
%% Import
f = DesignOutput(i).f;
RipPercent = DesignOutput(i).RipplePercent;
ILmax = DesignOutput(i).ILmax;
ILmin = DesignOutput(i).ILmin;
L = DesignOutput(i).L;
Lnum = DesignOutput(i).Lnum;
IL = DesignOutput(i).IL;
t = DesignOutput(i).t;
%%
figure;
plot(t.*1e3,IL,'k');
xlabel('Time (ms)'); ylabel('$I_L$ (A)');
%% Constraint 1: Fill Factor
CoreID = 1;
Wa = CoreData20kW.WindowAreaWa(CoreID)*1e-2; %%cm^2
skinDepth = 7.5/sqrt(f); %cm
Acond = pi*skinDepth^2;
Bmax = 0.5;
Ac = CoreData20kW.CrosssectionAe(CoreID)*1e-2; %% cm^2
N = round(1e4*L*ILmax/(Bmax*Ac));
Ku = N*Acond/Wa;
if Ku > 0.5
    disp(i);
    disp('Design is invalid')
end
CoreID = 1;
AT = N*ILmax;
y1 = CoreData20kW.AL1(CoreID);
x1 = CoreData20kW.AT1(CoreID);
y2 = CoreData20kW.AL2(CoreID);
x2 = CoreData20kW.AT2(CoreID);
y3 = CoreData20kW.AL3(CoreID);
x3 = CoreData20kW.AT3(CoreID);
y4 = CoreData20kW.AL4(CoreID);
x4 = CoreData20kW.AT4(CoreID);
y5 = CoreData20kW.AL5(CoreID);
x5 = CoreData20kW.AT5(CoreID);
x = [0 x1 x2 x3 x4 x5];
y = [CoreData20kW.ALNominal(i) y1 y2 y3 y4 y5];
AL_interpolated = interp1(x,y,AT);
%% Determining N
cons = 0;
while cons == 0
    if abs(AL_interpolated*N*N*1e-9-L) < L*1e-2
        cons = 1;
    end
    if AL_interpolated*N*N*1e-9 < L
        N = N + 1;
        AT = N*ILmax;
        AL_interpolated = interp1(x,y,AT);
    else
        N = N - 1;
        AT = N*ILmax;
        AL_interpolated = interp1(x,y,AT);
    end
end
i = 1;
disp(N);
Ku = N*Acond/Wa;
disp(Ku);
%%
