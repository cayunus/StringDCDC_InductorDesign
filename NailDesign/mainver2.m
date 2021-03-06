clear all
%% Constants
rho = 1.724e-5*(1+75*0.00393); %Ohm-mm
permData.name = {'14u';'26u';'40u';'60u';'75u';'90u';'125u'};
permData.a = {0.01;0.01;0.01;0.01;0.01;0.01;0.01};
permData.b = {4.938E-08; 5.266E-07; 2.177E-06; 2.142E-06; 3.885E-06;  5.830E-06; 2.209E-05};
permData.c = {2.000;1.819; 1.704; 1.855;1.819;1.819; 1.636};

lossData.name = {'14u';'26u';'40u';'60u';'75u';'90u';'125u'};
lossData.a = {80.55;52.36;52.36;44.30;44.30;44.30;44.30};
lossData.b = {1.988;1.988;1.988;1.988;1.988;1.988;1.988};
lossData.c = {1.541;1.541;1.541;1.541;1.541;1.541;1.541};
load('DesignData1.mat')
%% IL graph
figure;
plot(t.*1e3,IL,'k');
xlabel('Time (ms)'); ylabel('$I_L$ (A)');
%%
% Design Loop
for i = 1:30
    % Import

    f = DesignOutput(i).f;
    RipPercent = DesignOutput(i).RipplePercent;
    ILmax = DesignOutput(i).ILmax;
    ILmin = DesignOutput(i).ILmin; 
    L = DesignOutput(i).L;
    Lnum = DesignOutput(i).Lnum;
    IL = DesignOutput(i).IL;
    t = DesignOutput(i).t;
    %i=i-30;
    % Constraint 1: Fill Factor
    IsBroken = zeros(1,30);
    for CoreID = 1:96
        Wa = CoreData20kW.WindowAreaWa(CoreID); %% Window Area (mm^2)
        Bmax = 0.5; % Enes kudurabilir 
        Ac = CoreData20kW.CrosssectionAe(CoreID); %% Core Area (mm^2)
        N = round(1e4*L*ILmax/(Bmax*Ac));
        J = 3; % A/mm^2
        Acond = N*ILmax/J; % Conductor Area (mm)^2
        Ku = Acond/Wa; % Initial fill factor
 
        AT = N*ILmax; % Initial Ampere-Turn
        
        % Interpolation of AL with respect to Ampere-Turn
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
        x = [x1 x2 x3 x4 x5];
        y = [y1 y2 y3 y4 y5];
        AL_interpolated = interp1(x,y,AT);
        
        % Determining N
        cons = 0;
        while cons == 0
            
            if abs(AL_interpolated*N*N*1e-9-L) < L*10e-2 % Finish Condition
                cons = 1; % Finish Indicator
            end
            if AL_interpolated*N*N*1e-9 < L
                N = N + 1;
                AT = N*ILmax;
                if AT > x5 || AT < x1 % Error Indicator (AT is out-range)
                   cons = 1; 
                   IsBroken(CoreID) = 1;
                end
                AL_interpolated = interp1(x,y,AT);
            else
                N = N - 1;
                AT = N*ILmax;
                if AT > x5 || AT < x1 % Error Indicator (AT is out-range)
                   cons = 1;
                   IsBroken(CoreID) = 1;
                end
                AL_interpolated = interp1(x,y,AT);
            end
        end
 %       
        % Plot purposes
        Acondlist(CoreID) = N*ILmax/J; %mm^2
        Ku_list(CoreID) = Acondlist(CoreID)/Wa; 
        Acond = N*ILmax/J; % New conductor area
        Alpercentage(CoreID) = AL_interpolated/y(1);
        Nlist(CoreID) = N;
        flist(CoreID) = f;
        Llist(CoreID) = L;
        Bmax = 1e6*L*ILmax/(N*Ac);
        Bmin = 1e6*L*ILmin/(N*Ac);
        deltaB = Bmax-Bmin;
        Riplist(CoreID) = CoreData20kW.Volume(CoreID);


        % MLT interpolation
        y1 = CoreData20kW.MLT0(CoreID);
        x1 = 0;
        y2 = CoreData20kW.MLT20(CoreID);
        x2 = 0.2;
        y3 = CoreData20kW.MLT30(CoreID);
        x3 = 0.3;
        y4 = CoreData20kW.MLT40(CoreID);
        x4 = 0.4;

        y = [y1 y2 y3 y4];
        x = [x1 x2 x3 x4];
        MLT = interp1(x,y,Ku_list(CoreID));
        
        
        % Loss Calculations
        % Winding Loss
        Rwind = rho*N*(MLT)/(Acondlist(CoreID));
        WindingLoss(CoreID) = Lnum*Rwind*(rms(IL)^2);
        
        % Core Loss (Steinmetz)
        CoreLoss(CoreID) = Lnum*core_loss(deltaB,f./1e3,lossData,CoreID,CoreData20kW,i)*CoreData20kW.Volume(CoreID)*1e-3;
        B = 1e4*L*IL/(N*Ac);
        % Core Loss (Improved Steinmetz)
        GSEcore_losses(CoreID) = Lnum*GSEcore_loss(B,f,lossData,CoreID,CoreData20kW,t,IL,L,N,Ac,i);
    end

    Kulistt(i) = {Ku_list};
    % Valid Parameters
    CoreValidNoes(i) = {intersect(find(IsBroken == 0),find(Ku_list<0.4))};
    WindingLosses(i) = {WindingLoss(intersect(find(IsBroken == 0),find(Ku_list<0.4)))};
    %flistt(i) = {flist(intersect(find(IsBroken == 0),find(Ku_list<0.4)))};
    CoreLosses(i) = {CoreLoss(intersect(find(IsBroken == 0),find(Ku_list<0.4)))};
    CoreLossesGSE(i) = {GSEcore_losses(intersect(find(IsBroken == 0),find(Ku_list<0.4)))};
    Llistt(i) = {Llist};
    flistt(i) = {flist};
    Riplistt(i)= {Riplist(intersect(find(IsBroken == 0),find(Ku_list<0.4)))};
    CoreLossesIDs(i) = {intersect(find(IsBroken == 0),find(Ku_list<0.4))+(i-1)*96};
    Alpercentaget(i) = {Alpercentage};


end
%% Post-Process

%% Unite all solutions
WindingLossAll = [];
for i=1:30
WindingLossAll = [WindingLossAll cell2mat(WindingLosses(i))];
end
%
CoreLossAll = [];
for i=1:30
CoreLossAll = [CoreLossAll cell2mat(CoreLosses(i))];
end
%
CoreLossAllGSE = [];
for i=1:30
CoreLossAllGSE = [CoreLossAllGSE cell2mat(CoreLossesGSE(i))];
end

%% Loss plots
figure
bar([WindingLossAll;CoreLossAll./1e3]','stacked');
ylabel('Losses (W)')
xlabel('Design ID'),
legend('Winding Loss','Core Loss (Steinmetz)');
figure
bar([WindingLossAll;CoreLossAllGSE./1e3]','stacked');
ylabel('Losses (W)')
xlabel('Design ID'),
legend('Winding Loss','Core Loss (Improved-Steinmetz)' )
%%
A = [];
for i=1:30
A = [A cell2mat(Kulistt(i))];
end
%%
C = [];
for i=1:30
C = [C cell2mat(CoreLossesIDs(i))];
end
%%
figure
bar(C,[WindingLossAll;CoreLossAll./1e3]','stacked');
ylabel('Losses (W)')
xlabel('Design ID'),
legend('Winding Loss','Core Loss');
xlim([0 96*30])
ylim([0 500])
%%
for k = 1:30
xline(96*k,'--');
end
%%

figure
bar(A);
ylabel('$A_L$ (%)')
xlabel('Design ID'),
xlim([0 900])
xline([0.5])
%%
i = 26
    f = DesignOutput(i).f;
    RipPercent = DesignOutput(i).RipplePercent;
    ILmax = DesignOutput(i).ILmax;
    ILmin = DesignOutput(i).ILmin; 
    L = DesignOutput(i).L;
    Lnum = DesignOutput(i).Lnum;
    IL = DesignOutput(i).IL;
    t = DesignOutput(i).t;
%%
figure; boxplot([WindingLossAll;CoreLossAll]','Labels',{'Winding Loss','Core Loss'});ylabel('Loss (W)')