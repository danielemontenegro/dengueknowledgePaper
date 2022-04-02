%% TimeLag_CorrCoeff_AggCity1YrSld
% Computes time lag between Ovitrap data and Dengue occurrence, aggregated by the city.
% The parameters will be computed for 1 Yr slides.

clear all
clc
close all

seed = 1;
rng(seed);

%% Read dengue ocurrence and Ovitrap Data
T = readtable('../Dados_Modelagem.xlsx','sheet',4,...
              'ReadVariableNames',true,'ReadRowNames',true);
Neighborhood_NameAlph = T.Properties.RowNames;
Neighborhood_NameAlph([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};
DengueOcc = T.Variables';

MatFile = matfile('../Rearranged_Data.mat');
t_Week = MatFile.t_Date;
t = datenum(t_Week);
NYears = 4;
t_Month = linspace(datetime(2016,01,01),datetime(2019,12,31),NYears*12)';

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

% Weighting Ovitrap Data by population, filling missing values
EDI_Mat = fillmissing(EDI_Mat,'movmean',3);

M= 3;
b = ones(1,M)/M;
EDI_Mat = round(filtfilt(b,1,EDI_Mat));
DengueOcc = round(filtfilt(b,1,DengueOcc));

EDI_MatW = EDI_Mat.*W;

% Values aggregated for the city
Dengue = sum(DengueOcc,2);
EDI = nansum(EDI_Mat,2);
EDIW = nansum(EDI_MatW,2);

MDengue = mean(Dengue);

VarNames = {'Precipitation' 'Insolation' ...
                'Evaporation' 'Humidity' ...
                'Tmax','Tmin','TcomMed'};
            
MetMat = MatFile.MetDataMat;
Precipitation = fillmissing(MetMat(:,1),'movmedian',5);
% Precipitation = round(filtfilt(b,1,Precipitation));

%% Sliding 1 Year (Yr) computations

IndSld = 0:(NSamples-NWeeks_Yr);
NSld = length(IndSld);
IndWeeksYr = 1:NWeeks_Yr;

tLag = nan(1,NSld);
rLag = nan(1,NSld);
dDTW1 = nan(1,NSld);

for iSld = 1:NSld
    Ind = IndWeeksYr + IndSld(iSld);
    y = Dengue(Ind);
    x = EDIW(Ind);
    [CrossCorr,lags] = xcorr(y,x);
%     CrossCorr(lags<=0) = 0;
    [~,IndLag] = max(CrossCorr);
    Lag = lags(IndLag);
    tLag(iSld) = Lag;
    rLag(iSld) = corr(x(1:end-Lag),y(Lag+1:end));%,'Type','Spearman');
    dDTW1(iSld) = dtw(x(1:end-Lag),y(Lag+1:end));
end

%% Sliding 3 Years computations: estimating seazonality and tLag
IndSld = 0:NWeeks_Yr;
NSld = length(IndSld);
IndWeeks3Yr = 1:(3*NWeeks_Yr);
PairI = [1 1; 2 2; 1 2];
NPair = 3;
Data = [EDIW Dengue];

tLagCorr = nan(NSld,1);
tLagDFT = nan(NSld,NPair);

RLag = nan(NSld,1);


for iSld = 1:NSld
    IWeeks = IndWeeks3Yr + IndSld(iSld);
    x = EDIW(IWeeks);
    y = Dengue(IWeeks);
    
    [CrossCorr,lags] = xcorr(y,x);
%     CrossCorr(lags<=0) = 0;
    [~,IndLag] = max(CrossCorr);
    Lag = lags(IndLag);
    tLagCorr(iSld) = Lag;
    RLag(iSld) = corr(x(1:end-Lag),y(Lag+1:end),'Type','Spearman');
end

%% Plot tLag and rLag
fig2 = figure('units','normalized','outerposition',[0 0 1 1],'Color','w');

clr = [.93 .63 .13;0 0 1;.85 .33 .10];
IndSldYr = (0:NWeeks_Yr:NWeeks_Yr*3);
NYr = length(IndSldYr);
Years = 2016:2019;
R = nan(1,NYr);

for iYr = 1:NYr
    Ind = IndWeeksYr + IndSldYr(iYr);
    y = Dengue(Ind);%normalize(Dengue(Ind),'range');
    x = EDIW(Ind);%normalize(EDIW(Ind),'range');
    t1 = t(Ind);
    
    ax = subplot(2,4,1+iYr-1);
    lin1 = plot(t1,x,'Color',clr(1,:),'LineWidth',0.5,'Marker','.');
    hold on
    lin2 = plot(t1,y,'Color',clr(2,:),'LineWidth',0.5,'Marker','.');
%                 'Marker','.','MarkerSize',10);
    
    ax.XTick = t1(1:8:end);
    ax.XTickLabelRotation = 30;
    ax.TickLabelInterpreter = 'Latex';
    ax.FontSize = 12;
    datetick('x','mmm-yy','keepticks')
    str = {sprintf('Year: %d',Years(iYr))};
    title(str,'Interpreter','latex')
    ylim([0 1300])
    axis square;
    
    if iYr == 1
        lg = legend({'EDI(w)','Dengue'},'Interpreter','Latex');
        lg.Position = [0.4869    0.9324    0.0672    0.0569];
    end
    
    % Plot normalized series, shifted by tLag
    I = IndSldYr(iYr)+1;
    tLag01 = tLag(I);
    ax = subplot(2,4,1 + NYears + iYr-1);
    if iYr > 1
        x1 = EDIW(Ind-tLag01);
    else
        x1 = circshift(EDIW(Ind),tLag01);
        x1(1:tLag01) = nan;
    end
%     x1 = normalize(x1,'range');
    y1 = y;%normalize(y,'range');
    lin1 = plot(t1,x1,'Color',clr(1,:),'LineWidth',0.5,'Marker','.');
    hold on
    lin2 = plot(t1,y1,'Color',clr(2,:),'LineWidth',0.5,'Marker','.');
%                 'Marker','.','MarkerSize',10);
    
    ax.XTick = t1(1:8:end);
    ax.XTickLabelRotation = 30;
    ax.TickLabelInterpreter = 'Latex';
    ax.FontSize = 12;
    datetick('x','mmm-yy','keepticks')
    
    R(iYr) = corr(x1,y,'Rows','complete');
    str = {['EDI shifted $\rightarrow$' sprintf(' %d weeks',tLag01)],...
           sprintf('Corr: %.2f',R(iYr))};
    title(str,'Interpreter','latex')
    ylim([0 1300])
    axis square;
end
