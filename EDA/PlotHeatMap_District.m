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

%% Get Distric Indexs
Districts = ReducedTable.District;
Districts = Districts(ordNameAlph);
Districts(strcmp(Neighborhood,'Planalto')) = {'Oeste'};
% Merge Norte 1 and Norte 2
IndN1 = strcmp(Districts,'Norte 1');
IndN2 = strcmp(Districts,'Norte 2');
Districts(IndN1 | IndN2) = {'Norte'};

% Reorder data by Districts
[DistrictsOrd ,IndDistrict] = sort(Districts);

% Put DistrictsOrd in english
DistrictsOrd(strcmp(DistrictsOrd,'Norte')) = {'North'};
DistrictsOrd(strcmp(DistrictsOrd,'Sul')) = {'South'};
DistrictsOrd(strcmp(DistrictsOrd,'Leste')) = {'East'};
DistrictsOrd(strcmp(DistrictsOrd,'Oeste')) = {'West'};



NDistricts = unique(DistrictsOrd);

EDI_Mat = EDI_Mat(:,IndDistrict);
DengueOcc = DengueOcc(:,IndDistrict);
Neighborhood = Neighborhood(IndDistrict);

%%
T1 = readtable('../DADOS GERAIS_01.xlsx','sheet',2,'ReadVariableNames',true);
Neighborhood01 = T1.Bairros;
[Neighborhood02,ordNameAlph01] = sort(Neighborhood01);

ordNameAlph01([8 9]) = ordNameAlph01([9 8]); % Initialy was ordered firt 'Cidade Nova' and 
                                         % then 'Cidade da Esperança'. The
                                         % order was inverted
Neighborhood02 = Neighborhood01(ordNameAlph01);
Neighborhood02([8 20 21]) = {'Cidade Esperança','N.S. Apresentação','N.S. Nazaré'};

SocioEcoMat = T1{ordNameAlph01,2:end};
SocioEcoMat = SocioEcoMat(IndDistrict,:);
% SocioEcoMat = normalize(SocioEcoMat,'range');

IncomeAbove10Yr = SocioEcoMat(:,4);
IncomePerson = SocioEcoMat(:,3);
Population = SocioEcoMat(:,2);

Population = Population/max(Population);

W = repmat(Population',208,1);

%% Plot income versus districst
fig = figure('units','normalized','outerposition',[0.1 0.1 .9 .6],'Color','w');
IndNeigh = 1:NNeigh;
clr = [0 0 1;.93 .63 .13;.030 .75 .93;.85 .33 .10];
% scatter(IndNeigh,IncomePerson);
% hold on
% lsline
% LogDengueOcc = log2(DengueOcc);
% LogDengueOcc(LogDengueOcc<0) = nan;
% MeanDengueNeigh = nansum(LogDengueOcc);
% var = MeanDengueNeigh;

var = IncomePerson;
sc = gscatter(IndNeigh,var,DistrictsOrd,clr,[],[],'off');
DistrictNames = unique(DistrictsOrd);
strInd = 1;
IncomeDistricts = nan(4,1);
MeanDengueDistricts = nan(4,1);
cnt = 0;
for i1 = [1 3 4 2]
    cnt = cnt + 1;
    Ind = strcmp(DistrictsOrd,DistrictNames{i1});
    IncomeDistricts(cnt) = mean(var(Ind));
    MeanDengueDistricts(cnt) = mean(sum(DengueOcc(:,Ind)));
    
    EndInd = strInd + sum(Ind) - 1;
    ax1 = subplot(1,3,[1 2]);
    sc(i1) = plot(strInd:EndInd,var(Ind),'LineStyle','none');
    hold on;
    sc(i1).Marker = 'o';
    sc(i1).MarkerFaceColor = clr(i1,:);
    sc(i1).MarkerEdgeColor = 'k';
    sc(i1).MarkerSize = 6;
    strInd = EndInd + 1;
    
    ax2 = subplot(2,3,3);
    hold on;
    bar(cnt,IncomeDistricts(cnt),'FaceColor',clr(i1,:));
    
    ax3 = subplot(2,3,6);
    hold on;
    bar(cnt,MeanDengueDistricts(cnt),'FaceColor',clr(i1,:));
%     plot(IncomeDistricts(cnt),MeanDengueDistricts(cnt),'Marker','o','MarkerFaceColor',clr(i1,:),...
%          'MarkerEdgeColor','k','MarkerSize',6)
end
IndSul = strcmp(DistrictsOrd,'South');
IndOeste = strcmp(DistrictsOrd,'West');

PLimmit = (min(var(IndSul)) + max(var(IndOeste)))/2;

ax = subplot(ax1);
plot([1 36],[PLimmit PLimmit],'-.r')

xlabel('Neighborhoods by districts','Interpreter','latex','FontSize',09)
ylabel('Income by persons','Interpreter','latex','FontSize',09)
str = ['Districts vs Income by persons'];%sprintf('r = %.2f, p = %.2e',r,p);
title(str,'Interpreter','latex','FontSize',10)
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
axis([0 37 200 11000]);
box on
ax.YScale = 'log';

I1 = strcmp(Neighborhood,'Alecrim');
tx = text(1.2,var(I1),Neighborhood(I1),'FontSize',09);

I1 = strcmp(Neighborhood,'Mãe Luiza');
tx = text(6.2,var(I1),Neighborhood(I1),'FontSize',09);

ax = subplot(ax2);
% xlabel('Mean Income Person','Interpreter','latex','FontSize',09)
ylabel('R\$','Interpreter','latex','FontSize',09)
str = ['Income by persons'];%sprintf('r = %.2f, p = %.2e',r,p);
title(str,'Interpreter','latex','FontSize',10)
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
% axis square;
xlim([0 5])
box on;
ax.XTick = 1:4;
ax.XTickLabel = DistrictNames([1 3 4 2]);
grid minor
ax.YTickLabel = {'0','1k','2k','3k'};

ax = subplot(ax3);
% xlabel('Mean Income Person','Interpreter','latex','FontSize',09)
ylabel('Mean Acc.','Interpreter','latex','FontSize',09)
str = ['Dengue'];%sprintf('r = %.2f, p = %.2e',r,p);
title(str,'Interpreter','latex','FontSize',10)
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
% axis square;
xlim([0 5])
box on;
ax.XTick = 1:4;
ax.XTickLabel = DistrictNames([1 3 4 2]);
grid minor
ax.YTickLabel = {'0','1k','2k','3k'};

%% PCA
MeanDengue = sum(DengueOcc)';%normalize(mean(DengueOcc),'range')';
MeanEDIW = nansum((EDI_Mat))';
Data = [log10(SocioEcoMat(:,1)) log2(SocioEcoMat(:,2)) log2(SocioEcoMat(:,3))];
% Data = [log2(SocioEcoMat(:,3)) log10(MeanEDIW)];
[~,PC,~,tsquared,explained,~] = pca(Data,'NumComponents',2);

% Plot scatter plot PC1 vs PC2
fig = figure('units','normalized','outerposition',[0 0 1 1],'color','w');

ax = subplot(12,4,[8 24]);
hold on;
% IndSul = strcmp(DistrictsOrd,'Sul');
% IndOeste = strcmp(DistrictsOrd,'Oeste');

PLimmit = (min(PC(IndSul,1)) + max(PC(IndOeste,1)))/2;

plot([PLimmit PLimmit],[-2.1 2.1],'-.r')
PlotPCs(PC(:,1),PC(:,2),DistrictsOrd,clr)
hold on;
ax.Position(3) = 0.25;
axis square
axis([-3.5 4 -2.5 2.5])

%% Plot scatter plot PC1 vs dengue
ax = subplot(12,4,[32 48]);
hold on;
scatter(PC(:,1),log10(MeanDengue));
hold on
lsline
% sc = gscatter(PC(:,1),log10(MeanDengue),DistrictsOrd,clr,[],[],'off');
PlotPCs(PC(:,1),log10(MeanDengue),DistrictsOrd,clr)
[r,p] = corr(PC(:,1),log10(MeanDengue));

% for i1 = 1:4
%     sc(i1).Marker = 'o';
%     sc(i1).MarkerFaceColor = clr(i1,:);
%     sc(i1).MarkerEdgeColor = 'k';
%     sc(i1).MarkerSize = 6;
% end

  ax = gca;
xlabel('PC1','Interpreter','latex','FontSize',09)
ylabel('Dengue','Interpreter','latex','FontSize',09)
str = sprintf('r = %.2f, p = %.2e',r,p);
title(str,'Interpreter','latex','FontSize',10)
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
ylim([2 4.5])
box on

ax.Position(3) = 0.25;
axis square

%% Fit linear regression
Y = log10(MeanDengue);
lm = fitlm(Data(:,[2 3]),Y,'linear');

%% Plot heatmaps Dengue
ResultsPath = '..\Images_2021-09\';
[~,~,~] = mkdir(ResultsPath);

Mat = DengueOcc';
% Mat(Mat<0) = 0;
Title = 'Dengue Incidence';
ax2 = subplot(12,4,[1 3]);
ax1 = subplot(12,4,[1+4 3+4*5]);
HeatMapFcn(t,t_Month,Mat,Neighborhood,Title,ax1,ax2);
flagLegend = false;
PlotBarDistricts(t_Month(1),DistrictsOrd,ax1,clr,flagLegend);
ax1.XTickLabel = [];
ylabel('Neighborhoods by districts','Interpreter','latex','FontSize',12)

% print('-dpng','-r300',[ResultsPath 'HeatMap_DengueDistricts.png']);

% Plot for EDI

%% Plot EDI
% fig = figure('units','normalized','outerposition',[0 0 1 1],'color','w');

Mat = fillmissing(EDI_Mat.*W,'movmean',3)';
% b = ones(1,2)/2;
% Mat = round(filtfilt(b,1,Mat));

Title = 'EDI';
ax2 = subplot(12,4,[1 3]+4*6);
ax1 = subplot(12,4,[1+4 3+4*5]+4*6);
HeatMapFcn(t,t_Month,Mat,Neighborhood,Title,ax1,ax2);
flagLegend = true;
PlotBarDistricts(t_Month(1),DistrictsOrd,ax1,clr,flagLegend);
ylabel('Neighborhoods by districts','Interpreter','latex','FontSize',12)

print('-dpng','-r300',[ResultsPath 'HeatMap_Districts_PCA.png']);


%%  Nested functions

function PlotBarDistricts(t,DistrictsOrd,ax,clr,flagLegend)
    t = datenum(t);
    DistrictNames = unique(DistrictsOrd);
    NDistricts = length(DistrictNames);
%     clr = distinguishable_colors(NDistricts,{'b','r','k'});
    subplot(ax);
    hold on
    linDistricts = plot(nan(5));
    
    for iDistrict = 1:NDistricts
        IndDistrict = find(strcmp(DistrictsOrd,DistrictNames(iDistrict)));
%         IndDistrict = [IndDistrict(1) IndDistrict(end)];
        tDistrict = ones(size(IndDistrict))*t;
        linDistricts(iDistrict) = plot3(tDistrict,IndDistrict,ones(size(IndDistrict))*10);
        linDistricts(iDistrict).MarkerSize = 6;
        linDistricts(iDistrict).LineWidth = 1;
        linDistricts(iDistrict).Marker = 'o';
        linDistricts(iDistrict).LineStyle = 'none';
        linDistricts(iDistrict).MarkerFaceColor = clr(iDistrict,:);
        linDistricts(iDistrict).MarkerEdgeColor = 'k';%[.3 .3 .3];
    end
    if flagLegend
        lg = legend(linDistricts,DistrictNames,'Interpreter','Latex','FontSize',12);
        legend('Boxoff');
        lg.Position = [0.0511    0.4287    0.0662    0.1196];
    end
end

function PlotPCs(PC1,PC2,DistrictsOrd,clr)
DistrictNames = unique(DistrictsOrd);
    for iDistrict = 1:4
        IndDistrict = (strcmp(DistrictsOrd,DistrictNames(iDistrict)));
        linDistricts = plot(PC1(IndDistrict),PC2(IndDistrict));
        linDistricts.MarkerSize = 6;
%         linDistricts.LineWidth = 1;
        linDistricts.Marker = 'o';
        linDistricts.LineStyle = 'none';
        linDistricts.MarkerFaceColor = clr(iDistrict,:);
        linDistricts.MarkerEdgeColor = 'k';%[.3 .3 .3];
    end
%     lg = legend(DistrictNames,'Interpreter','Latex','FontSize',12);
    
    ax = gca;
    xlabel('PC1','Interpreter','latex','FontSize',09)
    ylabel('PC2','Interpreter','latex','FontSize',09)
    title('Scatter plot','Interpreter','latex')
    ax.TickLabelInterpreter = 'Latex';
    ax.FontSize = 12;
    
    box on
end

function HeatMapFcn(t_Week,t_Month,Mat,Neighborhood_Name,Title,ax1,ax2)
    NNeighborhood = size(Mat,1);
    Mat = log2(Mat);
    Mat(Mat<0) = 0;
    t_Week = datenum(t_Week);
    subplot(ax1);
    contourf(t_Week,1:NNeighborhood,...
                     Mat,30,'lines','none')
    ax1.Visible = 'on';
    ax1.FontSize = 12;
    ax1.TickLabelInterpreter = 'Latex';
    ax1.XTick = t_Week(1:12:end);
        % ax1.XTickLabel = DateStr_Month;
    ax1.XTickLabelRotation = 20;
    datetick('x','mmm-yy','keepticks')

    ax1.YTick = [];%1:NNeighborhood;
%     ax1.YTickLabelRotation = 30;
%     ax1.YTickLabel = Neighborhood_Name;

    c = colorbar;
    c.Position(1) = 0.704;
    c.Position(3) = c.Position(3)*.6;
    c.Label.String = ['Colormap ($log_2$)'];
    c.TickLabelInterpreter = 'latex';
    c.Label.Interpreter = 'latex';
    colormap('jet')

    x1 = sum(Mat);

    subplot(ax2);
    lin2 = plot(datenum(t_Week),x1,'LineW',1.5);

    ax2.Visible = 'off';
    tl = title([Title]);
    tl.Interpreter = 'Latex';
    tl.FontSize = 12;
    tl.Visible = 'on';
    tl.Position(2) = tl.Position(2) - 80;
    axis tight;
%     legend(Title,'Interpreter','Latex')
%     legend('boxoff')
end
