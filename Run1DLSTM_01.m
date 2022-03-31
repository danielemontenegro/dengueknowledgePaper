%% Run 1D - LSTM models.
% The script use as input the agragated values for
% the predictor for all neighborhoods. The output will be the agregated
% values for Dengue incidence.
% 
% As predictor the models will use Dengue incidence or EDI (for past weeks).

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
         
OPI_Mat = MatFile.EggIndice_Agregated(:,:,1);
OPI_Mat = OPI_Mat(ordNameAlph,:)';
ODI_Mat = MatFile.EggIndice_Agregated(:,:,2);
ODI_Mat = ODI_Mat(ordNameAlph,:)';

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

%% Lets pre-processing, formating and organizinfg the data

% Smooth the data that will be used as input for training LSTM model
% % x1 = round(filtfilt(b,1,x));
Dengue = nanmean(DengueOcc,2)';
EDI = nanmean(ODI_Mat,2)';
EDIW = nanmean(ODI_Mat.*W,2)';

NSamples = length(Dengue);
NTrain =  round(.8*NSamples);
% NTest = NSamples - NTrain1;
NTest = NSamples - NTrain - 1;

%% Train and test the different models
NRep = 30;
InName = {'Dengue','EDI'};
OutName = 'Dengue';
NBackSamples = [1 3:6];

IndTestOut = (NTrain+1:NSamples);
tTest = t(IndTestOut);
numTimeStepsTest = length(tTest);

YTest = Dengue(IndTestOut);
% set input and output
y1 = log2(Dengue);
b = ones(1,3)/3;
%y1 = filtfilt(b,1,y1);

NMdls = length(InName)*length(NBackSamples);
YPred = nan(numTimeStepsTest,NRep,NMdls);

cntMdl = 0;
tStart = tic;
for iIn = 1:2
    if iIn == 1
        x1 = log2(Dengue);
    else
        x1 = log2(EDI);
    end
    %x1 = filtfilt(b,1,x1);
    for iBack = NBackSamples
        IndTRainOut = iBack+1:NTrain;
        
        cnt = 0;
        if iBack == 1
            vector = iBack;
            IndTRainIn = nan(size(IndTRainOut));
            IndTestIn = nan(size(IndTestOut));
        else
            vector = (iBack -2):iBack;%iBack:-1:(iBack -2);
            IndTRainIn = nan(3,size(IndTRainOut,2));
            IndTestIn = nan(3,size(IndTestOut,2));
        end
        for iiBack = vector
            cnt = cnt + 1;
            IndTRainIn(cnt,:) = IndTRainOut - iiBack;
            IndTestIn(cnt,:) = IndTestOut - iiBack;
        end

        XTrain = x1(IndTRainIn); 
        YTrain = y1(IndTRainOut); 
%         XTest = x1(IndTestIn);
        if iIn == 1
            XTest = log2(Dengue(IndTestIn));
        else
            XTest = log2(EDI(IndTestIn));
        end
        cntMdl = cntMdl + 1;
        YPred(:,:,cntMdl) = TrainLSTM(XTrain,YTrain,XTest,NRep,numTimeStepsTest);
    end
end
etime_Hr = toc(tStart)/3600;
sprintf('Time duration is hr: %.2f',etime_Hr)
ModelName = 'Models_1DLSTM_2022_02_04';
save([ModelName '_EvalResults.mat'],'YPred','YTest','tTest',...
     'Neighborhood_NameAlph','-v7.3');

%% Nested functions
function [x1,y1] = setInOut(iIn,iOut,Dengue,EDI)
    % set input
    if iIn == 1
        x1 = Dengue;
    else
        x1 = EDI;
    end

    % set output
    if iOut == 1
        y1 = Dengue;
    else
        y1 = EDI;
    end
    
    % log 2 transformation
    x1 = log2(x1);
    x1(x1<0) = 0;
    
    y1 = log2(y1);
    y1(y1<0) = 0;
end

function [XTrainLSTM,XTestLSTM] = SetXTrainXTest(x1,NBackSamples,NTrain,NSamples)
    if NBackSamples == 5
        BackSamples = (NBackSamples-2):NBackSamples;
        XTrainLSTM = nan(3,NTrain-NBackSamples+1);
        XTestLSTM = nan(3,length(NTrain+1:NSamples-NBackSamples));
    elseif NBackSamples >= 3
        BackSamples = 1:3;%(NBackSamples-2):NBackSamples;
        XTrainLSTM = nan(3,NTrain-NBackSamples+1);
        XTestLSTM = nan(3,length(NTrain+1:NSamples-NBackSamples));
    else
        BackSamples = 1;%NBackSamples;
        XTrainLSTM = nan(1,NTrain-NBackSamples+1);
        XTestLSTM = nan(1,length(NTrain+1:NSamples-NBackSamples));
    end
    
    for iSample  = BackSamples
        IndTrainSamples = iSample:NTrain-NBackSamples+iSample;
%         XTrain1 = x1(IndTrainSamples);
        XTrainLSTM(iSample,:) = x1(IndTrainSamples);

        IndTestSamples = NTrain+iSample:NSamples-NBackSamples+iSample-1;
        XTestLSTM(iSample,:) = x1(IndTestSamples);
    end
end

function [XTrainLSTM,XTestLSTM] = SetXTrainXTest_Old(x1,NBackSamples,NTrain,NSamples)
    XTrainLSTM = nan(NBackSamples,NTrain-NBackSamples+1);

    XTestLSTM = nan(NBackSamples,length(NTrain+1:NSamples-NBackSamples));

    for iSample  = 1:NBackSamples
        IndTrainSamples = iSample:NTrain-NBackSamples+iSample;
%         XTrain1 = x1(IndTrainSamples);
        XTrainLSTM(iSample,:) = x1(IndTrainSamples);

        IndTestSamples = NTrain+iSample:NSamples-NBackSamples+iSample-1;
        XTestLSTM(iSample,:) = x1(IndTestSamples);
    end
end

function YPred = TrainLSTM(XTrain,YTrain,XTest,NRep,numTimeStepsTest)
    YPred = zeros(numTimeStepsTest,NRep);
    % Layers and training options
    inputSize = size(XTrain,1);
    numResponses = 1;
    numHiddenUnits = 100;
    layersLSTM = [ ...
        sequenceInputLayer(inputSize)
        lstmLayer(numHiddenUnits)
        fullyConnectedLayer(numResponses)
        regressionLayer];

    optsLSTM = trainingOptions('adam', ...
            'MaxEpochs',250, ...
            'GradientThreshold',1, ...
            'InitialLearnRate',0.005, ...
            'LearnRateSchedule','piecewise', ...
            'LearnRateDropPeriod',125, ...
            'LearnRateDropFactor',0.2, ...
            'Verbose',0,'MiniBatchSize',64);
    
    % Train and predict
    for iRep = 1:NRep
        % Train LSTM
        fprintf('Working on rep %d from  %d\n',iRep, NRep)
        [netLSTM,infoLSTM] = trainNetwork(XTrain,YTrain,layersLSTM,optsLSTM);

         %%
        netLSTM = resetState(netLSTM);
        netLSTM = predictAndUpdateState(netLSTM,XTrain);
        
        numTimeStepsTest = size(YPred,1);
        for i = 1:numTimeStepsTest
            [netLSTM,YPred(i,iRep)] = predictAndUpdateState(netLSTM,XTest(:,i));
        end
        clc
    end
end

