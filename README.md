# Code

Data-Driven Computational Intelligence Applied to Forecast Dengue Outbreaks: a
case study in the city of Natal, RN- Brazil

License: Attribution-NonCommercial-ShareAlike 4.0 International

Paper Dengue

For the code in the folder ‘EDA’
PlotHeatMap_District.m

This code allows to produce:

The heatmaps for Dengue incidence and EDI, and the PCA scatter plots presented in Figure 1.
Supplementary Figure 1.

Note: If further explanation is needed, please refer to the description of the figures mentioned above.
Acc1YrWindowRepresentation.m 

This code is for Representation of accumulated values for 1 year sliding windows. See Supplementary Figure 4 description for further information.
TimeLag_CorrCoeff_AggCity01.m

For estimating periodicities for Dengue incidence and EDI time series and time lag between them. See Supplementary Figure 2 description for further information.
EDA_01.m

Time series by monthly accumulated values and its pairwise associations. See Figure 5 description.

Accumulated values for 1-year sliding windows and their pairwise relations. See Figure 6 description.

Bar graph of the normalized accumulated values by years from 2016 to 2019 at Natal’s city. See Supplementary Figure 3 description.
TimeSeries_CorrCoeff_AggCity1YrSld.m

Computes time lag and correlation coefficient between Ovitrap data and Dengue occurrence. The parameters are computed for 1 Yr slides. See Figure 4 description.

For the code in the folder ‘DL_Models’
ModelsPerform_1DLSTM_01.m

Plot the performance of LSTM models trained for dengue incidence forecasting. See Figure 2 and Figure 3 descriptions for more details. 
Run1DLSTM_01.m

Used for trained LSTM models for forecasting aggregate dengue values for the whole municipality. As predictors, it was used either aggregate dengue values or aggregate EDI values. The models were trained with the following samples of the time series used as a predictor (referencing i the target sample of the dengue time series):

i-1 previous sample (1 past sample),
i-3,i-2,i-1 previous samples (3:1 past samples),
i-4,i-3,i-2 previous samples (4:2 past samples),
i-5,i-4,i-3 previous samples (5:3 past samples),
i-6,i-5,i-4 previous samples (6:4 past sample). 

Data

DADOS GERAIS_01.xlsx
We use the sheet ‘Renda por Bairro’ for socioeconomic data.
Dados_Modelagem.xlsx

We use the sheet ‘Casos de Dengue’ for dengue incidence data.
InternamentosDengueNatal.xlsx

We use the 2° sheet of the file for dengue hospitalization data.
Rearranged_Data.mat

A Matlab data file, we use the ‘EggIndice_Agregated’ 3D array to load EDI time series.
Once we load the .mat file, we can access to EDI time series:

EggIndice_Agregated(:,:,2)

