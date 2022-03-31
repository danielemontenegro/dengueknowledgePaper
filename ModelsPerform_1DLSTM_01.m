%% Performance evaluation from 1D LSTM models

clear all
clc
close all

%% Compare 1D LSTM Models results
MatFile = matfile('Models_1DLSTM_2022_02_04_EvalResults.mat');
YPredMdls = MatFile.YPred;
YTestMdls = MatFile.YTest;
tTestMdls = MatFile.tTest;

NRep = 30;
InName = {'D','O'};%{'Dengue','EDI'};
OutName = 'D';%{'Dengue','EDI'};
NBackSamples = [1 3:6];

NMdls = size(YPredMdls,3);
NMdls1 = NMdls/2; % fr the same In->Out
%% Compute mean Log2 RMSE and std error for each mdl
MeanLogRMSE = nan(NMdls,1);
StdELogRMSE = nan(NMdls,1);
MeanR = nan(NMdls,1);
StdER = nan(NMdls,1);
MdlNames = cell(NMdls,1);
MdlNames1 = cell(NMdls,1);

cnt = 0;
for iIn = 1:2
    for iBack = NBackSamples
        cnt = cnt + 1;
        [MeanLogRMSE(cnt),StdELogRMSE(cnt)] = ComputeRMSE(YPredMdls(:,:,cnt),YTestMdls);
        [MeanR(cnt),StdER(cnt)] = ComputeR(YPredMdls(:,:,cnt),YTestMdls);
        if iBack == 1
            str = '1 past sample';
        else
            str = sprintf('%d:%d past samples',iBack,iBack-2);
        end
        MdlNames1{cnt} = str;%[InName{iIn} '->' OutName num2str(iBack) 'Sample'];
        MdlNames{cnt} = [InName{iIn} '$\rightarrow$' OutName];
    end
    
end
%% Plots
NBackSamples;
% Plot bar graphs for error and performance of the 1DLSTM models
RMSE = [MeanLogRMSE(1:NMdls1) MeanLogRMSE((NMdls1+1):end)]';
eRMSE = [StdELogRMSE(1:NMdls1) StdELogRMSE((NMdls1+1):end)]';
R = [MeanR(1:NMdls1) MeanR((NMdls1+1):end)]';
eR = [StdER(1:NMdls1) StdER((NMdls1+1):end)]';
fig = figure('units','normalized','outerposition',[0 0.1 1 .8]);
set(gcf,'color','w');

ax = subplot(1,3,1);
hold on;
for iMdl = 1:NMdls1
    bRMSE(iMdl) = bar(iMdl,RMSE(1,iMdl));
    eBar(iMdl) = errorbar(iMdl,RMSE(1,iMdl),eRMSE(1,iMdl),'Color','k');
    
    bar(iMdl+1+NMdls1,RMSE(2,iMdl),'FaceColor',bRMSE(iMdl).FaceColor);
    errorbar(iMdl+1+NMdls1,RMSE(2,iMdl),eRMSE(2,iMdl),'Color','k');
end
ylabel('RMSE','Interpreter','latex')
title('A) Model errors','Interpreter','latex')
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
ax.XTick = [3 9];
ax.XTickLabel = {'$D_{i-j}\rightarrow D_i$','$O_{i-j}\rightarrow D_i$'};
% {'D$\rightarrow$D','D$\rightarrow$O','O$\rightarrow$D','O$\rightarrow$O'};
axis square;
box on;
% ylim([0.2 .8])

ax = subplot(1,3,2);
hold on
for iMdl = 1:NMdls1
%     bR = bar(R);
    bRMSE(iMdl) = bar(iMdl,R(1,iMdl),'FaceColor',bRMSE(iMdl).FaceColor);
    errorbar(iMdl,R(1,iMdl),eR(1,iMdl),'Color','k');
    
    bar(iMdl+1+NMdls1,R(2,iMdl),'FaceColor',bRMSE(iMdl).FaceColor);
    errorbar(iMdl+1+NMdls1,R(2,iMdl),eR(2,iMdl),'Color','k');
end
% xlabel('Model input $\rightarrow$ output','Interpreter','latex')
ylabel('r','Interpreter','latex')
title('B) Model performance','Interpreter','latex')
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
ax.XTick = [3 9];
ax.XTickLabel = {'$D_{i-j}\rightarrow D_i$','$O_{i-j}\rightarrow D_i$'};
axis square;
box on;
ylim([0.4 1])

lg = legend(bRMSE,MdlNames1(1:NMdls1),'Interpreter','Latex');
lg.Position = [0.4853    0.8816    0.0818    0.0829];
legend('Boxoff')

% Plot scatter plot with error and performance

ax = subplot(1,3,3);
ptsDD = plot(1:NMdls1);
ptsOD = plot(1:NMdls1);
cla
hold on  
for iMdl = 1:NMdls1
    ptsDD(iMdl) = plot(RMSE(1,iMdl),R(1,iMdl),'LineStyle','none','marker','o',...
                     'MarkerFaceColor',bRMSE(iMdl).FaceColor,'MarkerEdgeColor','k');
               
    ptsOD(iMdl) = plot(RMSE(2,iMdl),R(2,iMdl),'LineStyle','none','marker','d',...
                     'MarkerFaceColor',bRMSE(iMdl).FaceColor,'MarkerEdgeColor','k');
end
% tx = text(MeanLogRMSE+.2,MeanR,MdlNames,'Interpreter','latex','FontSize',10);

ylabel('r','Interpreter','latex')
xlabel('RMSE','Interpreter','latex')
title('C) Error vs Performance','Interpreter','latex')
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 12;
axis square;
ylim([0.55 1])

str = {'$D_{i-j}\rightarrow D_i$','$O_{i-j}\rightarrow D_i$'};
lg = legend([ptsDD(1) ptsOD(end)],str,'Interpreter','Latex');
legend('Boxoff')

ResultsPath = '..\Images_2021-09\';
[~,~,~] = mkdir(ResultsPath);
% print('-dpng','-r300', [ResultsPath 'Models_1DLSTM_02_Perform.png']);

%% Compare D->D last sample vs O->D last 3 samples
YPred_DD = 2.^YPredMdls(:,:,1);
YPred_OD = 2.^YPredMdls(:,:,10);

YTest_DD = YTestMdls';
YTest_OD = YTestMdls';

tTestDD = tTestMdls;
tTestOD = tTestMdls;

%%
fig = figure('units','normalized','outerposition',[0.1 0.1 .7 .8]);
set(gcf,'color','w');

% Plot correlation
ax = subplot(2,2,1);
sc1 = plot(YTest_DD,mean(YPred_DD,2),'Marker','o','MarkerEdgeColor','k',...
          'MarkerFaceColor',bRMSE(1).FaceColor,'MarkerSize',4,'LineStyle','none');
ls = lsline;
ls.Color = [.4 .4 .4];

str1 = '$D \rightarrow D$';
[r,p] = corr(YTest_DD,mean(YPred_DD,2));
str2 = sprintf('r = %.2f, p = %.2e',r,p);
title(str2,'Interpreter','latex')
xlabel('Known','Interpreter','latex')
ylabel('Predicted','Interpreter','latex')
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 10;
axis square;
axis([0 35 0 35]);

ax = subplot(2,2,3);
sc1 = plot(YTest_OD,mean(YPred_OD,2),'Marker','o','MarkerEdgeColor','k',...
          'MarkerFaceColor',bRMSE(5).FaceColor,'MarkerSize',4,'LineStyle','none');
ls = lsline;
ls.Color = [.4 .4 .4];

str1 = '$O \rightarrow D$';
[r,p] = corr(YTest_OD,mean(YPred_OD,2));
str2 = sprintf('r = %.2f, p = %.2e',r,p);
title(str2,'Interpreter','latex')
xlabel('Known','Interpreter','latex')
ylabel('Predicted','Interpreter','latex')
ax.TickLabelInterpreter = 'Latex';
ax.FontSize = 10;
axis square;
axis([0 35 0 35]);

% Plot time seires
ax = subplot(2,2,2);
% plot(tTestDD,YPred_DD,':','Color',bR(1).FaceColor);
hold on;
lin1 = plot(tTestDD,mean(YPred_DD,2),'Color',bRMSE(1).FaceColor,'LineWidth',1.5);
lin2 = plot(tTestDD,YTest_DD,'Color','k');
title('$D_{i-j} \rightarrow D_i$','Interpreter','latex');
ylabel('Mean Dengue Occ','Interpreter','latex')
ylim([0 35])
ax.XTick = tTestDD(1:3:end);
ax.XTickLabelRotation = 30;
datetick('x','mmm-yy','keepticks')
box on
lg = legend([lin1 lin2],{'Predicted','Known'});
legend('Boxoff')

ax = subplot(2,2,4);
% plot(tTestOD,YPred_OD,':','Color',bR(5).FaceColor);
hold on;
lin1 = plot(tTestOD,mean(YPred_OD,2),'Color',bRMSE(5).FaceColor,'LineWidth',1.5);
lin2 = plot(tTestOD,YTest_OD,'Color','k');
title('$O_{i-j} \rightarrow D_i$','Interpreter','latex');
ylabel('Mean Dengue Occ','Interpreter','latex')
ylim([0 35])
ax.XTick = tTestOD(1:3:end);
    % ax1.XTickLabel = DateStr_Month;
ax.XTickLabelRotation = 30;
datetick('x','mmm-yy','keepticks')
box on
lg = legend([lin1 lin2],{'Predicted','Known'});
legend('Boxoff')

% print('-dpng','-r300', [ResultsPath 'Models_1DLSTM_02_Perform01.png']);
%% Nested functions

function [MeanLogRMSE,StdELogRMSE] = ComputeRMSE(YPred,YTest)
    NRep = size(YPred,2);
    YPred = 2.^YPred;
    YTest = (YTest)';
    YTest = repmat(YTest,1,NRep);
    Error = YTest - YPred;
    RMSE = rms(Error);
    MeanLogRMSE = mean(RMSE);
    StdELogRMSE = std(RMSE)/sqrt(NRep);
end

function [MeanR,StdER] = ComputeR(YPred,YTest)
    NRep = size(YPred,2);
    YTest = YTest';
    YPred = 2.^YPred;
    YTest = repmat(YTest,1,NRep);
    
    R = corr(YTest,YPred);
    R = diag(R);
    MeanR = mean(R);
    StdER = std(R)/sqrt(NRep);
end