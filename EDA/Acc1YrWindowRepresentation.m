%% Representation of acumulated values for 1 year sliding windows

clear all
clc
close all

seed = 1;
rng(seed);

%%
MatFile = matfile('../Rearranged_Data.mat');
t_Week = MatFile.t_Date;
t = datenum(t_Week);
NSamples = length(t);
NYears = 4;

% NSamples = length(t);
% ReducedTable = MatFile.ReducedTable;
% Neighborhood_Name = ReducedTable.Neighborhood_Name;
% [Neighborhood,ordNameAlph] = sort(Neighborhood_Name);
% ordNameAlph([8 9]) = ordNameAlph([9 8]); % Initialy was ordered firt 'Cidade Nova' and 
%                                          % then 'Cidade da Esperança'. The
%                                          % order was inverted
% Neighborhood = Neighborhood_Name(ordNameAlph);
% Neighborhood([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};
         
EDI_Mat = MatFile.EggIndice_Agregated(:,:,2)';

%% Acc variables by months
% Values aggregated for the city
EDI = nansum(EDI_Mat,2);


IndSldMonth = (1:4:NSamples)-1;

NMonth4Yrs = 48;
EDI_AccMonth = nan(NMonth4Yrs,1);

% set time vectors
tVec = datevec(t);
Yrs = [2016*ones(12,1);2017*ones(12,1);2018*ones(12,1);2019*ones(12,1)];
Month = repmat((1:12)',4,1);
CentralDay = 15*ones(NMonth4Yrs,1);
tHosp = datetime(Yrs,Month,CentralDay);
tMonth = datenum(tHosp);

Years = 2016:2019;
Months = 1:12;
cnt = 0;
for iYr = Years
    IndYr = tVec(:,1) == iYr;
    for iMonth = Months
        cnt = cnt + 1;
        IndMonth = tVec(:,2) == iMonth;
        Ind = IndYr & IndMonth;
        
        EDI_AccMonth(cnt) = sum(EDI(Ind));
    end
end
EDI_AccMonth = normalize(EDI_AccMonth,'range');

%% Acc 1-yr sliding window 
NWeeks_Yr = 12;
IndSld = 0:(NMonth4Yrs-NWeeks_Yr);
NSld = length(IndSld);
AccEDI = nan(1,NSld);

YearsStr = {'2016','2017','2018','2019'};

IndWeeksYr = 1:(NWeeks_Yr);
for iSld = 1:NSld
    Ind = IndWeeksYr + IndSld(iSld);
    AccEDI(iSld) = sum(EDI_AccMonth(Ind));%/sum(EDI_AccMonth);
end
AccEDI = normalize(AccEDI,'range');

%% Acc 1-yr sliding window version 2
IndSld1 = 0:36;
IndSld2 = IndSld1+12;

AccEDI_01 = nan(size(AccEDI));
AccEDI_01(1) = 0;
for iSld = 2:NSld
    Ind1 = IndSld1(iSld);
    Ind2 = IndSld2(iSld);
    AccEDI_01(iSld) = AccEDI_01(iSld-1) + diff(EDI_AccMonth([Ind1 Ind2]));
end
AccEDI_01 = normalize(AccEDI_01,'range');
%% Plot EDI by months and Acc 1-Yr values
fig1 = figure('units','normalized','outerposition',[0 .3 1 0.7],'Color','w');
var = EDI_AccMonth+2;

ax = gca;hold on;
xCoor = tMonth([1 12 12 1]);
MWind = max(var(1:12)) + 0.2;
mWind = min(var(1:12)) - 0.2;
yCoor = [mWind mWind MWind MWind];
rect = patch(xCoor,yCoor,[.9 .9 .9]);
rect.EdgeColor = [.3 .3 .3];%[.9 .9 .9];
rect.LineStyle = '--';

str = '$\rightarrow$ 1 month steps, $j = 0, 1, ..., 36$';
tx = text(tMonth(12)+10,MWind,str,'FontSize',13,...
          'Interpreter','Latex');

yCoor = (mWind + AccEDI(1))/2;
str1 = '$y_j = \displaystyle\sum_{i=j}^{j+11} x_i$';
tx = text(tMonth(12)+10,yCoor,str1,'FontSize',15,...
          'Interpreter','Latex');

lin = line(tMonth([12 12]),[mWind-0.2 AccEDI(1)+0.2],'color','k');
Mrk1 = line(tMonth(12),mWind-0.2,'MarkerEdgeC','b','MarkerFaceC','k','Marker','^');
Mrk2 = line(tMonth(12),AccEDI(1)+0.2,'MarkerEdgeC','b','MarkerFaceC','k','Marker','v');

lin1 = plot(tMonth,var,'Color',[.6 .6 .6],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',[0 0.555 1],'MarkerSize',4);

ax.XTick = tMonth;
ax.XTickLabelRotation = 30;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
axis([tMonth(1) tMonth(end) -.1 max(var)+.1])
ax.XTickLabel = datestr(tMonth,'mmm-yy');
ax.TickLength = [0.005 0.005];
ax.YTick = [mean(AccEDI) mean(var)];
ax.YTickLabel = {'$y$','$x$'};
% ax.YTickLabelRotation = 20;
tMonth1 = tMonth(end-NSld+1:end);

lin2 = plot(tMonth1,AccEDI,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',[0 0.655 1],'MarkerSize',6);
box on;
grid minor

lg = legend([lin1 lin2 rect],{'$x$: Monthly samples','$y$: 1-Yr Acc',...
            '1Yr sliding window, $j=0$'},'Interpreter','Latex');
lg.Location = 'southwest';


