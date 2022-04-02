% HospitalizationsEDA01
clear all
clc
close all

seed = 1;
rng(seed);

%% Read Hospitalizations
clc
DataHosp = readtable('../InternamentosDengueNatal.xlsx','sheet',2,...
              'ReadVariableNames',true,'ReadRowNames',false);
DataHosp = DataHosp(:,4:45);

NMonth4Yrs = 48;

Yrs = [2016*ones(12,1);2017*ones(12,1);2018*ones(12,1);2019*ones(12,1)];
Month = repmat((1:12)',4,1);
CentralDay = 15*ones(NMonth4Yrs,1);

tHosp = datetime(Yrs,Month,CentralDay);
tMonth = datenum(tHosp);

%% Include missing values
tMonthStr = DataHosp.Properties.VariableNames;
YrStr = cell(length(tMonthStr),1);
MonthStrData = cell(length(tMonthStr),1);

for iStr = 1:length(tMonthStr)
    tMonthStr(iStr) = {tMonthStr{iStr}(2:end)};
    YrStr(iStr) = {tMonthStr{iStr}(1:4)};
    MonthStrData(iStr) = {tMonthStr{iStr}(6:end)};
end

MonthStrData(strcmp(MonthStrData,'Abr')) = {'Apr'};
MonthStrData(strcmp(MonthStrData,'Mai')) = {'May'};
MonthStrData(strcmp(MonthStrData,'Ago')) = {'Aug'};
MonthStrData(strcmp(MonthStrData,'Set')) = {'Sep'};
MonthStrData(strcmp(MonthStrData,'Dez')) = {'Dec'};
MonthStrData(strcmp(MonthStrData,'Fev')) = {'Feb'};
MonthStrData(strcmp(MonthStrData,'Out')) = {'Oct'};
for iStr = 1:length(tMonthStr)
    MonthStrData(iStr) = { [YrStr{iStr} '_' MonthStrData{iStr}]};
end

MonthStr = cellstr(datestr(tMonth,'yyyy_mmm'));

HospMonth1 = DataHosp{1,:}';
HospMonth = zeros(48,1);

[I1,I2] = ismember(MonthStrData,MonthStr);

HospMonth(I2) = HospMonth1;

%% Read dengue ocurrence and Precipitation Data
T = readtable('../Dados_Modelagem.xlsx','sheet',4,...
              'ReadVariableNames',true,'ReadRowNames',true);
Neighborhood_NameAlph = T.Properties.RowNames;
Neighborhood_NameAlph([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};
DengueOcc = T.Variables';

MatFile = matfile('../Rearranged_Data.mat');
t_Week = MatFile.t_Date;
t = datenum(t_Week);
NYears = 4;

NNeigh = length(Neighborhood_NameAlph);
NSamples = length(t);
NWeeks_Yr = 52;

%% Read EDI
ReducedTable = MatFile.ReducedTable;
Neighborhood_Name = ReducedTable.Neighborhood_Name;
[Neighborhood,ordNameAlph] = sort(Neighborhood_Name);
ordNameAlph([8 9]) = ordNameAlph([9 8]); % Initialy was ordered firt 'Cidade Nova' and 
                                         % then 'Cidade da Esperança'. The
                                         % order was inverted
Neighborhood = Neighborhood_Name(ordNameAlph);
Neighborhood([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};
         
EDI_Mat = MatFile.EggIndice_Agregated(:,:,2);
EDI_Mat = EDI_Mat(ordNameAlph,:)';

% Filling missing values
EDI_Mat = fillmissing(EDI_Mat,'movmean',3);

%% Read Precipitation data
MetMat = MatFile.MetDataMat;
Precipitation = fillmissing(MetMat(:,1),'movmedian',5);

%% Socio-econimic data
T1 = readtable('../DADOS GERAIS_01.xlsx','sheet',2,'ReadVariableNames',true);
Neighborhood01 = T1.Bairros;
[Neighborhood02,ordNameAlph01] = sort(Neighborhood01);

ordNameAlph01([8 9]) = ordNameAlph01([9 8]); % Initialy was ordered firt 'Cidade Nova' and 
                                         % then 'Cidade da Esperança'. The
                                         % order was inverted
Neighborhood02 = Neighborhood01(ordNameAlph01);
Neighborhood02([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};

SocioEcoMat = T1{ordNameAlph01,2:end};
Population = SocioEcoMat(:,2);
Population = normalize(Population,'range');
W = repmat(Population',208,1);

%% Acc variables by months
M= 3;
b = ones(1,M)/M;
EDI_Mat = round(filtfilt(b,1,EDI_Mat));
DengueOcc = round(filtfilt(b,1,DengueOcc));
Precipitation = round(filtfilt(b,1,Precipitation));

% Values aggregated for the city
Dengue = sum(DengueOcc,2);
EDI = nansum(EDI_Mat,2);
EDI_MatW = EDI_Mat.*W;
EDIW = nansum(EDI_MatW,2);

IndSldMonth = (1:4:NSamples)-1;

tVec = datevec(t);

EDI_AccMonth = nan(size(HospMonth));
Dengue_AccMonth = nan(size(HospMonth));
Precip_AccMonth = nan(size(HospMonth));

Years = 2016:2019;
Months = 1:12;
cnt = 0;
for iYr = Years
    IndYr = tVec(:,1) == iYr;
    for iMonth = Months
        cnt = cnt + 1;
        IndMonth = tVec(:,2) == iMonth;
        Ind = IndYr & IndMonth;
        
        EDI_AccMonth(cnt) = sum(EDIW(Ind));
        Dengue_AccMonth(cnt) = sum(Dengue(Ind));
        Precip_AccMonth(cnt) = sum(Precipitation(Ind));
    end
end
%% Plot time series
fig1 = figure('units','normalized','outerposition',[0.1 0.1 .6 .9],'Color','w');

ax = subplot(3,1,1);
lin1 = plot(t,EDIW,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','.',...
            'MarkerEdgeColor','g');

ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 30;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
datetick('x','mmm-yy','keepticks')
str = {'EDI (weekly samples)'};
title(str,'Interpreter','latex')
ylabel('Weighted velues','Interpreter','latex')
        
ax = subplot(3,1,2);
lin1 = plot(tMonth,HospMonth,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',[.9 .1 .1]);
        
ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 30;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
datetick('x','mmm-yy','keepticks')
str = {'Dengue Hospitalizations (monthly samples)'};
title(str,'Interpreter','latex')
ylabel('No. cases','Interpreter','latex')

ax = subplot(3,1,3);
lin1 = plot(t,Dengue,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','.',...
            'MarkerEdgeColor','r');

ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 30;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
datetick('x','mmm-yy','keepticks')
str = {'Dengue Incidence (weekly samples)'};
title(str,'Interpreter','latex')
ylabel('No. cases','Interpreter','latex')

%% Plot Accumulated time series
fig1 = figure('units','normalized','outerposition',[0.1 0 .9 1],'Color','w');

ax = subplot(4,4,[1 3]);
var = normalize(Precip_AccMonth,'range');
lin1 = plot(tMonth,var,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor','b');

ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 20;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
xlim([tMonth(1) tMonth(end)])
ax.XTickLabel = datestr(tMonth(1:2:end),'mmm-yy');
% str = {'Precipitation (monthly samples)'};
% title(str,'Interpreter','latex')
% ylabel('Units','Interpreter','latex')

ax = subplot(4,4,[1 3]+4);
var = normalize(EDI_AccMonth,'range');
lin2 = plot(tMonth,var,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',[0    0.655    1]);

ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 20;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
xlim([tMonth(1) tMonth(end)])
ax.XTickLabel = datestr(tMonth(1:2:end),'mmm-yy');
str = {'EDI (monthly samples)'};
% title(str,'Interpreter','latex')
% ylabel('Weighted values','Interpreter','latex')
        
ax = subplot(4,4,[1 3]+8);
var = normalize(Dengue_AccMonth,'range');
lin3 = plot(tMonth,var,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',[.85 .55 .1]);

ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 20;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
ax.XTickLabel = datestr(tMonth(1:2:end),'mmm-yy');
xlim([tMonth(1) tMonth(end)])
str = {'Dengue Incidence (monthly samples)'};
% title(str,'Interpreter','latex')
yl = ylabel('Normalized Values','Interpreter','latex');
yl.Position(2) = 1.4;
yl.Position(1) = yl.Position(1) - 30;

ax = subplot(4,4,[1 3]+12);
var = normalize(HospMonth,'range');
lin4 = plot(tMonth,var,'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor','r');
        
ax.XTick = tMonth(1:2:end);
ax.XTickLabelRotation = 20;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
ax.XTickLabel = datestr(tMonth(1:2:end),'mmm-yy');
xlim([tMonth(1) tMonth(end)])
str = {'Dengue Hospitalizations (monthly samples)'};
% title(str,'Interpreter','latex')
% ylabel('No. cases','Interpreter','latex')


DataNames = {'V1) Precipitation','V2) EDI','V3) Dengue Incidence','V4) Hospitalizations'};
lg = legend([lin1 lin2 lin3 lin4],DataNames,'Interpreter','latex','FontSize',10);
lg.Position = [0.76    0.8160    0.1314    0.0897];

axSeriesCorr = subplot(4,4,[8 12]);
%% Test relations between Acc values by years
NWeeks_Yr = 12;
IndSld = 0:(NMonth4Yrs-NWeeks_Yr);
NSld = length(IndSld);
AccEDI = nan(1,NSld);
AccDengue = nan(1,NSld);
AccDengueHosp = nan(1,NSld);
AccPrecip = nan(1,NSld);

YearsStr = {'2016','2017','2018','2019'};

IndWeeksYr = 1:(NWeeks_Yr);
for iSld = 1:NSld
    Ind = IndWeeksYr + IndSld(iSld);
    AccEDI(iSld) = sum(EDI_AccMonth(Ind));%/sum(EDI_AccMonth);
    AccDengue(iSld) = sum(Dengue_AccMonth(Ind));%/sum(Dengue_AccMonth);
    AccPrecip(iSld) = sum(Precip_AccMonth(Ind));%/sum(Precip_AccMonth);
    AccDengueHosp(iSld) =  sum(HospMonth(Ind));%/sum(HospMonth);
end
[~,IOrdEDI_Yr] = sort(AccEDI);

DataAccYr = [AccPrecip;AccEDI;AccDengue;AccDengueHosp]';
DataAccYr = normalize(DataAccYr,'range');

%%
Lines = [lin1 lin2 lin3 lin4];
fig2 = figure('units','normalized','outerposition',[0.1 0 .9 1],'Color','w');
tMonth1 = tMonth(end-NSld+1:end);
for iDat = 1:4
    ax = subplot(4,4,[1 3]+4*(iDat-1));
    Lines(iDat) = plot(tMonth1,DataAccYr(:,iDat),'Color',[.4 .4 .4],'LineWidth',0.5,'Marker','o',...
            'MarkerFaceColor',Lines(iDat).MarkerFaceColor);

    
    ax.TickLabelInterpreter = 'Latex';
    ax.FontSize = 11;
    ax.XTick = tMonth1(1:2:end);
    ax.XTickLabelRotation = 20;
    ax.TickLabelInterpreter = 'Latex';
    ax.FontSize = 12;
    ax.XTickLabel = datestr(tMonth1(1:2:end),'mmm-yy');
    xlim([tMonth1(1) tMonth1(end)])
%     ylabel('No. cases','Interpreter','latex')
end
lg = legend(Lines,DataNames,'Interpreter','latex','FontSize',10);
lg.Position = [0.76    0.8160    0.1314    0.0897];

yl = ylabel('Normalized Values','Interpreter','latex');
yl.Position(2) = 1.4;
yl.Position(1) = yl.Position(1) - 30;

%% Estimate the distance between Acc Time series
Data_AccMonth = [Precip_AccMonth EDI_AccMonth Dengue_AccMonth HospMonth];
% Data_AccMonth = normalize(Data_AccMonth);

RR = 1 - pdist(Data_AccMonth','correlation');

%% Get Pairwise combination Indexs
Pairs = nchoosek(1:4,2);
R = nan(length(Pairs),1);
PairNames = cell(length(Pairs),1);
clr = distinguishable_colors(length(Pairs),{'k'});
Ax = [3 4 7 8 11 12];
for iPair = 1:length(Pairs)
    I = Pairs(iPair,:);
    x = DataAccYr(:,I(1));
    y = DataAccYr(:,I(2));
    [r,p] = corr(x,y,'Type','Spearman');
    R(iPair) = r;
    PairNames(iPair) = {['V$_{' sprintf('%d%d',I) '}$']};
end

%% Resampled Accumulated Link Estimator (ALE)
% Note: If the 'Accumulated' term it is not appropiate we can think in Aggregated, Aggregative
% or Accurate 
NRep = 100;
NSamplesRep = 25;
ISld1 = 1:NSld;
ISld2 = 1:NMonth4Yrs;

R1 = nan(NRep,6);
R2 = nan(NRep,6);
axAccCorr = subplot(4,4,[8 12]);
Bar = bar(1:6,ones(1,6));
for iPair = 1:length(Pairs)
    I = Pairs(iPair,:);
    x1 = DataAccYr(:,I(1));
    y1 = DataAccYr(:,I(2));
    
    x2 = Data_AccMonth(:,I(1));
    y2 = Data_AccMonth(:,I(2));
    for iRep = 1:NRep 
        Ind_Resample1 = sort(datasample(ISld1,NSamplesRep,'Replace',false));
        R1(iRep,iPair) = corr(x1(Ind_Resample1),y1(Ind_Resample1),'Type','Spearman');
%         R1(iRep,iPair) = dtw(x1(Ind_Resample1),y1(Ind_Resample1));
        
        Ind_Resample2 = sort(datasample(ISld2,NSamplesRep,'Replace',false));
        R2(iRep,iPair) = corr(x2(Ind_Resample2),y2(Ind_Resample2),'Type','Spearman');
%         R2(iRep,iPair) = dtw(x2(Ind_Resample2),y2(Ind_Resample2));
    end
    FColor = (Lines(I(1)).MarkerFaceColor + Lines(I(2)).MarkerFaceColor)/2;
    
    figure(fig2);
    r = mean(R1(:,iPair));
    ax = subplot(axAccCorr);
    Bar(iPair) = bar(iPair,r);
    Bar(iPair).FaceColor = FColor;
    Bar(iPair).BarWidth = .4;
    hold on
    
    r = mean(R2(:,iPair));
    figure(fig1);
    ax = subplot(axSeriesCorr);
    Bar(iPair) = bar(iPair,r);
    Bar(iPair).FaceColor = FColor;
    Bar(iPair).BarWidth = .4;
    hold on
end

figure(fig1);
ax = subplot(axSeriesCorr);
StdError = std(R2)/sqrt(NRep);
eBar = errorbar(1:6,mean(R2),StdError,'LineStyle','none','LineW',1);
title('Corr. between variable pairs','Interpreter','latex')
ylabel('r','Interpreter','latex');
xlim([0 7])
box on;
ax.XTick = 1:6;
ax.XTickLabel = PairNames;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
grid minor
% ylim([0 1]);
axis square;

figure(fig2);
ax = subplot(axAccCorr);
StdError = std(R1)/sqrt(NRep);
eBar = errorbar(1:6,mean(R1),StdError,'LineStyle','none','LineW',1);
title('Corr. between variable pairs','Interpreter','latex')
ylabel('r','Interpreter','latex');
xlim([0 7])
box on;
ax.XTick = 1:6;
ax.XTickLabel = PairNames;
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
grid minor
axis square;

%% Plot accumulated values EDI, Dengu and 
figure('units','normalized','outerposition',[0.1 0.1 .55 .7],'Color','w');

Dat = DataAccYr(1:12:NSld,:);
[~,IOrdDengue_Yr] = sort(Dat(:,3),'descend');

ax = gca;%subplot(1,2,1);
Bar = bar(Dat(IOrdDengue_Yr,:)');
% set(Bar,'BarWidth',.6)
ax.XTickLabel = {'Precip.','EDI','Dengue','Hosp.'};
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
str = {'Acc. values', ...
       'Normalized by max'};
title(str,'Interpreter','latex')
lg = legend(YearsStr(IOrdDengue_Yr),'Interpreter','Latex');
lg.Position = [0.0571    0.7010    0.1179    0.1951];
axis square;

grid minor
ylim([0 1.1]);



