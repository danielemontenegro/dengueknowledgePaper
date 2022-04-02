%% TimeLag_CorrCoeff_AggCity01
% Compute time lag between Ovitrap data and Dengue occurrence, aggregated by the city.

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

%%
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

%% Plot autocorelaton for seasonality estimations and cross-correlation for timelag estimation
fig = figure('units','normalized','outerposition',[0.1 0 0.6 1],'color','w');

% Plots for autocorrelation
% ax = subplot(3,4,[1 3]);
% x = EDI;
% PlotAutoCorr(x,ax,'EDI')
% 
% ax = subplot(3,4,[1 3]+4);
% x = Dengue;
% PlotAutoCorr(x,ax,'Dengue')

ax = subplot(2,2,1);%subplot(3,4,4);
x = EDI;
PlotSpectrum(x,ax)
xlabel('freq (weeks$^{-1}$)','Interpreter','latex');
axis square;

ax = subplot(2,2,2);%subplot(3,4,8);
y = Dengue;
PlotSpectrum(y,ax)
xlabel('freq (weeks$^{-1}$)','Interpreter','latex');
axis square;

ax1 = subplot(2,2,3);%subplot(3,4,[1 3]+8);
ax2 = subplot(2,2,4);%subplot(3,4,12);
PlotCrossCorr(y,EDIW,ax1,ax2)

function PlotSpectrum(x,ax)
    x = x - mean(x);
    YFreq = Spectrum(x);
    YFreq = YFreq/max(YFreq);
    Nf = length(YFreq);
    fs = 1; % week
    f = linspace(0,fs/2,Nf);
    [PeakF,PeakFLoc] = findpeaks(YFreq,'NPeaks',1,'SortStr','descend');
    
    % Plot for frequency analysis
    plot(f,YFreq,'b');
    Mrk3 = line(f(PeakFLoc),PeakF,'MarkerEdgeC','b','MarkerFaceC','r','Marker','o');
    text(f(PeakFLoc+3),PeakF,sprintf('%.5f',f(PeakFLoc)),'Interpreter','latex',...
         'FontSize',12);

    ax.TickLabelInterpreter = 'latex';
    ax.FontSize = 12;
    title(['T$_{Season}$: ',sprintf('%d weeks',round(1/f(PeakFLoc)))],'Interpreter','latex');
    xlim([0 0.2])
    ylim([0 1.1]);
%     set([Mrk1 Mrk2 Mrk3],'MarkerSize',3)
end

function PlotCrossCorr(x,y,ax1,ax2)
    [XCorr,lag] = xcorr(x,y,104);
    
    XCorr = normalize(XCorr,'range');
    [Peak,PeakLoc] = findpeaks(XCorr,'NPeaks',1,'SortStr','descend');
    
    ax = subplot(ax1);
    plot(lag,XCorr,'b');
    Mrk3 = line(lag(PeakLoc),Peak,'MarkerEdgeC','b','MarkerFaceC','r','Marker','o');
    text(lag(PeakLoc+3),Peak,sprintf('%d weeks',lag(PeakLoc)),'Interpreter','latex',...
         'FontSize',13);
     
    ax.TickLabelInterpreter = 'latex';
    ax.FontSize = 12;
    axis tight
    ylim([0 1.1]);
    xlabel('tlag (weeks)','Interpreter','latex')
    title('c) Cross-correlation: EDI vs Dengue','Interpreter','latex');
    axis square;
    
      % Plot correlations
      LagWeek = lag(PeakLoc);
      x1 = x(LagWeek+1:end);
      y1 = y(1:end - LagWeek);
      [r,p] =  corr(x1,y1);
      
      ax = subplot(ax2);
      sc = scatter(x1,y1);
      sc.Marker = '.';
      ls = lsline;
      xlabel('EDI','Interpreter','latex')
      ylabel('Dengue','Interpreter','latex')
      title(sprintf('d) r = %.2f, p $<$ 0.001',r),'Interpreter','latex')
      axis square;
      box on
end

function  Y = Spectrum(x)
%     nfft = length(x);
%     X = fft(x,nfft);
%     % Hold the half part of the spectrum
%     P2 = abs(X/nfft);
%     Y = P2(1:nfft/2+1);
%     Y(2:end-1) = 2*Y(2:end-1);
    Window = 52*3;
    NOverlap = Window -1;
    nfft = Window;
    Y = pwelch(x,Window,NOverlap,nfft)
end