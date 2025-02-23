%% Tomaso Muzzu - UCL - 6th June 2021

% Part of revision analysis: correlation between trial onset responses and
% perturbation responses
% 1) measure this with MI_pert vs 1.5s/0.5s response at trial onset.
% 2) see if there are differences across batches and experienced/naive


%% Functions to plot Figure 2 - direction tuning
if ~exist('ProjectData','var')
    [ProjectData AM_UnitResponses AM_Param AM_Speed AM_UOI SelectedResponses AM_UnitResponses_smooth] = LoadDataALL;
end
thres = 95;
% first 7 animals
if  size(ProjectData,1) == 37
    CTRL_exp = 0;
    Animal_1st_idx = [1 5 7 12 15 24 31];
    
    if ~exist('PertResp_units','var')
        % select only perturbation responsive units
        load('AUC_shuffled.mat')
        Sh_responses = AUC_shuffled(:,2:end);
        p_pert_th = prctile(Sh_responses(:),thres);
        PertResp_units = (AUC_shuffled(:,1)>p_pert_th);
        % select only pos. modulated perturbation responsive units
        load('DM_pert_shuffled.mat')
        %DM = DM_sh(:,1);
        DM_sign_i(:,1) = DM>0;
        DM_sign_i(:,2) = DM<=0;
        % select only pos. modulated perturbation responsive units
        PertRespUnits_pos = PertResp_units & DM_sign_i(:,1);
        PertRespUnits_neg = PertResp_units & DM_sign_i(:,2);
    end
    
elseif size(ProjectData,1) == 10
    CTRL_exp = 1;
    % naive animals
    Animal_1st_idx = [1 4 7];
    if ~exist('PertResp_units','var')
        % select only perturbation responsive units
        load('AUC_shuffled_CTRL_1.mat')
        Sh_responses = AUC_shuffled(:,2:end);
        p_pert_th = prctile(Sh_responses(:),thres);
        PertResp_units = (AUC_shuffled(:,1)>p_pert_th);
        % select only pos. modulated perturbation responsive units
        load('DM_CTRL.mat')
        %DM = DM_sh(:,1);
        DM_sign_i(:,1) = DM>0;
        DM_sign_i(:,2) = DM<=0;
        % select only pos. modulated perturbation responsive units
        PertRespUnits_pos = PertResp_units & DM_sign_i(:,1);
        PertRespUnits_neg = PertResp_units & DM_sign_i(:,2);
    end
    
else
    % select only perturbation responsive units
    load('AUC_shuffled_CTRL_1.mat')
    AUC_shuffled_CTRL = AUC_shuffled;
    AUC_shuffled_pp_CTRL = AUC_shuffled_pp;
    load('AUC_shuffled.mat')
    AUC_shuffled = cat(1,AUC_shuffled,AUC_shuffled_CTRL);
    AUC_shuffled_pp = cat(1,AUC_shuffled_pp,AUC_shuffled_pp_CTRL);
    Sh_responses = AUC_shuffled(:,2:end);
    p_pert_th = prctile(Sh_responses(:),thres);
    PertResp_units = (AUC_shuffled(:,1)>p_pert_th);
    % select only pos. modulated perturbation responsive units
    load('DM_ALL.mat')
    DM_sign_i(:,1) = DM>0;
    DM_sign_i(:,2) = DM<=0;
    % select only pos. modulated perturbation responsive units
    PertRespUnits_pos = PertResp_units & DM_sign_i(:,1);
    PertRespUnits_neg = PertResp_units & DM_sign_i(:,2);
end

%% direction
if size(AM_UOI,2)==1
    SelectedCells = AM_UOI;
else
    SelectedCells = AM_UOI(:,1) & AM_UOI(:,2);
end
% select trials of interest and control trials as well
Trials_PertON = AM_Param(:,:,3)==1; % find indexes where perturbation is on
Trials_PertOFF= AM_Param(:,:,3)==0; % find indexes where perturbation is off

BonvisionFR = 60; %Hz
trialSide_samples = 60;
trialSide_seconds = 1;

PertOnsets = AM_Param(:,:,4); % 2D matrix
PertOffsets = AM_Param(:,:,5); % 2D matrix
[v min_i(1)] = max(PertOnsets(:)); % find the latest moment when pert onset happens
[v min_i(2)] = max(PertOffsets(:)); % find the latest moment when pert offset happens

ReferSize = [size(AM_Param,1),size(AM_Param,2)];
[trial_el(1), trial_el(2)] = ind2sub(ReferSize,min_i(1)); % 2D index of minimum pert onset time

Rec = AM_Param(trial_el(1), trial_el(2),1);
% define timeline of example recording
TrialStart = ProjectData.Session_data{Rec,1}.ACInfo{1,1}.trialStartsEnds(trial_el(1),1);
TrialEnd = ProjectData.Session_data{Rec,1}.ACInfo{1,1}.trialStartsEnds(trial_el(1),2)-TrialStart;
TrialStart = 0;
TimeLine = linspace(TrialStart-trialSide_seconds, ...
                    TrialEnd+trialSide_seconds,...
                    size(AM_UnitResponses_smooth,3)); % -1 seconds
[v po_i(1)] = min(abs(TimeLine-min(PertOnsets(:))));
[v po_i(2)] = min(abs(TimeLine-min(PertOffsets(:))));
SelectedCells = AM_UOI;
param_sel = AM_Param(:,SelectedCells,:);
UnitResponses_smooth = AM_UnitResponses_smooth(:,SelectedCells,:);


%% load AUC values of the units from control group
% load('AUC_shuffled_CTRL_1.mat')
AUC_units = AUC_shuffled(:,1);
p_sh = prctile(reshape(AUC_shuffled(:,2:end),1,size(AUC_shuffled(:,2:end),1)*size(AUC_shuffled(:,2:end),2)),thres);


%% look at response after 0.5s and 1.5s from trial onset
param_sel = AM_Param(:,SelectedCells,:);
Param = squeeze(param_sel(:,:,3));
w_1_2 = [0.25 1.75]; % from the trail onset, seconds after which look for max
w_width = 0.5; % window size in which to look for max response
trialonset_w = trialSide_seconds+[w_1_2(1) w_1_2(1)+w_width ; ...
                                  w_1_2(2) w_1_2(2)+w_width];
trialonset_w  = trialonset_w*BonvisionFR;
r= 1; clear VisResp_05_15
for i = 1:size(Param,2)
    % select trial responses
    Responses = Param(:,i);
    % scrub responses
    Responses = logical(Responses(~isnan(Responses)));
    UnitResponse = mean(squeeze(UnitResponses_smooth(1:length(Responses),i,:)))*60;
    UnitResponse = UnitResponse/max(UnitResponse);
    VisResp_05_15(i) = nanmax(UnitResponse(trialonset_w(1,1):trialonset_w(1,2)-1))/ ...
                       nanmax(UnitResponse(trialonset_w(2,1):trialonset_w(2,2)-1));
end
Resp_grouping = (PertRespUnits_pos*2) + PertRespUnits_neg;

%% can we predict if it is a perturbation unit?
tic
clear AUC_OntrialOnset AUC_OntrialOnset_sh
parfor i = 1:size(Param,2)
    % select trial responses
    TrialType = Param(:,i);
    % scrub responses
    TrialType = logical(TrialType(~isnan(TrialType)));
    UnitResponse = (squeeze(UnitResponses_smooth(1:length(TrialType),i,:)))*60;
    UnitResponse = (UnitResponse-min(UnitResponse(:)))/(max(UnitResponse(:))+min(UnitResponse(:)));
    SingleUnitResponse = UnitResponse(:,trialSide_samples:trialonset_w(2,2)-1);
    SingleUnitResponse =  nanmax(UnitResponse(:,trialonset_w(1,1):trialonset_w(1,2)-1)')./ ...
                       nanmax(UnitResponse(:,trialonset_w(2,1):trialonset_w(2,2)-1)');
          SingleUnitResponse(isnan(SingleUnitResponse)) = 0   
    mdl = fitglm(SingleUnitResponse,TrialType,'Distribution','binomial','Link','logit');
    scores = mdl.Fitted.Probability;
    % step 3: compute the ROC and evaluate the AUC for each unit
    [X,Y,T,AUC1] = perfcurve(TrialType,scores,'true');
    AUC_OntrialOnset(i) = AUC1;  
    
    Class_trainer = [SingleUnitResponse', TrialType];
   
    subplot(1,3,1)
    imagesc(SingleUnitResponse)
    subplot(1,3,2)
    imagesc(TrialType)
    subplot(1,3,3)
    imagesc(UnitResponse)
    
    figure
    plot(X,Y)
    xlabel('False positive rate')
    ylabel('True positive rate')
    title('ROC for Classification by Logistic Regression')
    
    for sh_i = 1:1000
        % shuffle perturbation trals
        Responses_sh = TrialType(randperm(length(TrialType)));
        % apply logistic model
        mdl = fitglm(SingleUnitResponse,Responses_sh,'Distribution','binomial','Link','logit');
        scores = mdl.Fitted.Probability;
        % step 3: compute the ROC and evaluate the AUC for each unit
        [X,Y,T,AUC1] = perfcurve(TrialType,scores,1);
        AUC_OntrialOnset_sh(i,sh_i) = AUC1;
    end
    i
end
toc

thsd_95 = prctile(AUC_OntrialOnset_sh(:),95);
figure
edges = 0:0.01:1;
h1 = histogram(AUC_OntrialOnset_sh(:),edges,'Normalization','probability');
hold on
plot([thsd_95 thsd_95], [0 0.1],'k')
h2 = histogram(AUC_OntrialOnset(:),edges,'Normalization','probability');

find(AUC_OntrialOnset>thsd_95)

sum(PertRespUnits_pos)
sum(PertRespUnits_pos(find(AUC_OntrialOnset>thsd_95)))
sum(PertRespUnits_neg)
sum(PertRespUnits_neg(find(AUC_OntrialOnset>thsd_95)))

%% correlation trial by trial of MI vs ratio


%% plot MI vs ratio of trial onset response
figure
plot([1 1], [-1 1],'-.','Color',[0.5 0.5 0.5])
hold on
plot([0 4], [0 0],'-.','Color',[0.5 0.5 0.5])
%plot(VisResp_05_15(Resp_grouping>0),DM(Resp_grouping>0),'.')
%[p, s] = polyfit(VisResp_05_15(Resp_grouping>0),DM(Resp_grouping>0),1);
x = VisResp_05_15(Resp_grouping>=0);
y = DM(Resp_grouping>=0);
fitobject = fit(x' ,y' ,'poly1');
plot(fitobject,x,y,'.r')
hold on
x1 = VisResp_05_15(Resp_grouping==0);
y1 = DM(Resp_grouping==0);
fitobject1 = fit(x1' ,y1' ,'poly1');
plot(fitobject1,x1,y1,'.k')
mdl = fitlm(x,y);
mdl1 = fitlm(x1,y1);
p_MI_slope = [mdl.Coefficients.Estimate(2) mdl.Coefficients.pValue(2)];
p_MI_slope1 = [mdl1.Coefficients.Estimate(2) mdl1.Coefficients.pValue(2)];
ll = legend({'','',...
            'Pert. Resp. Units' ,['y=' num2str(mdl.Coefficients.Estimate(1),1) '+' num2str(mdl.Coefficients.Estimate(2),1) 'x'],...
            'Rest Units' ,['y=' num2str(mdl1.Coefficients.Estimate(1),1) '+' num2str(mdl1.Coefficients.Estimate(2),1) 'x']},...
            'fontsize',10);
ll.Color = 'none'; ll.EdgeColor = 'none';
title(['linear fits, p=' num2str(p_MI_slope(2),2) ', p=' num2str(p_MI_slope1(2),2)]);
xlim([0 4]); ylim([-1 1])
xlabel('Transient/sustained response ratio');
ylabel('Perturbation modulation index')
set(gca,'TickDir','out','box','off')

% plot positive VS negative
figure
plot([1 1], [-1 1],'-.','Color',[0.5 0.5 0.5])
hold on
plot([0 4], [0 0],'-.','Color',[0.5 0.5 0.5])
%plot(VisResp_05_15(Resp_grouping>0),DM(Resp_grouping>0),'.')
%[p, s] = polyfit(VisResp_05_15(Resp_grouping>0),DM(Resp_grouping>0),1);
x = VisResp_05_15(Resp_grouping>0);
y = DM(Resp_grouping>0);
fitobject = fit(x' ,y' ,'poly1');
plot(fitobject,x,y,'.r')
hold on
x1 = VisResp_05_15(Resp_grouping==0);
y1 = DM(Resp_grouping==0);
fitobject1 = fit(x1' ,y1' ,'poly1');
plot(fitobject1,x1,y1,'.k')
mdl = fitlm(x,y);
mdl1 = fitlm(x1,y1);
p_MI_slope = [mdl.Coefficients.Estimate(2) mdl.Coefficients.pValue(2)];
p_MI_slope1 = [mdl1.Coefficients.Estimate(2) mdl1.Coefficients.pValue(2)];
ll = legend({'','',...
            'Pert. Resp. Units' ,['y=' num2str(mdl.Coefficients.Estimate(1),1) '+' num2str(mdl.Coefficients.Estimate(2),1) 'x'],...
            'Rest Units' ,['y=' num2str(mdl1.Coefficients.Estimate(1),1) '+' num2str(mdl1.Coefficients.Estimate(2),1) 'x']},...
            'fontsize',10);
ll.Color = 'none'; ll.EdgeColor = 'none';
title(['linear fits, p=' num2str(p_MI_slope(2),2) ', p=' num2str(p_MI_slope1(2),2)]);
xlim([0 4]); ylim([-1 1])
xlabel('Transient/sustained response ratio');
ylabel('Perturbation modulation index')
set(gca,'TickDir','out','box','off')


figure
subplot(1,2,1)
plot(VisResp_05_15(Resp_grouping>0 & Units_Exp),DM(Resp_grouping>0 & Units_Exp),'.')
xlim([0 4]); ylim([-2 2])
subplot(1,2,2)
plot(VisResp_05_15(Resp_grouping>0 & ~Units_Exp),DM(Resp_grouping>0 & ~Units_Exp),'.')
xlim([0 4]); ylim([-2 2])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for all units 
Resp_grouping = (PertRespUnits_pos*2) + PertRespUnits_neg;
cluster_pert = Resp_grouping>=1;
cluster_rest = Resp_grouping==0;
figure
subplot(3,1,1)
edges = 0:0.05:4;
h1 = histogram(VisResp_05_15(cluster_pert),edges,'EdgeColor','none','Normalization','probability');
hold on
h2 = histogram(VisResp_05_15(cluster_rest),edges,'EdgeColor','none','Normalization','probability');
ylabel('Units');
title('All mice'); clear Ratios
Ratios(1,:) = [mean(VisResp_05_15(cluster_pert)) std(VisResp_05_15(cluster_pert))/sqrt(sum(cluster_pert)) median(VisResp_05_15(cluster_pert))];
Ratios(2,:) = [mean(VisResp_05_15(cluster_rest)) std(VisResp_05_15(cluster_rest))/sqrt(sum(cluster_rest)) median(VisResp_05_15(cluster_rest))];
legend({['Pert Units, meanratio=' num2str(Ratios(1,1),2) '�' num2str(Ratios(1,2),2) ', median=' num2str(Ratios(1,3),3)]...
        ['Rest, meanratio=' num2str(Ratios(2,1),2) '�' num2str(Ratios(2,2),2) ', median=' num2str(Ratios(2,3),3)]})
subplot(3,1,2)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2),VisResp_05_15(Resp_grouping==1)),2) ', ' ...
       '(+ vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2),VisResp_05_15(Resp_grouping==0)),2) ', ' ...
       '(- vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1),VisResp_05_15(Resp_grouping==0)),2) ', ' ...
       '(pr vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping>=1),VisResp_05_15(Resp_grouping==0)),2)  ]);
legend({['pert. signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping>=2)-1),2)], ...
       ['rest signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==0)-1),2)]});
subplot(3,1,3)
Data2Plot = [VisResp_05_15(cluster_pert), VisResp_05_15(cluster_rest)];
u_ns = [ones(length(VisResp_05_15(cluster_pert)),1)*1; ...
        ones(length(VisResp_05_15(cluster_rest)),1)*2];
boxplot(Data2Plot,u_ns,'PlotStyle','compact','Colors','rbk','Orientation','horizontal','OutlierSize',1)
xlabel('All mice');
ylabel('Transient/Sustained ratio');
set(gca,'TickDir','out','box','off')
xlim([0 4])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for all units for exp VS naive
Resp_grouping = (PertRespUnits_pos*2) + PertRespUnits_neg;
cluster_pert = Resp_grouping>=0 & Units_Exp;
cluster_rest = Resp_grouping>=0 & ~Units_Exp;
figure
subplot(3,1,1)
edges = 0:0.05:4;
h1 = histogram(VisResp_05_15(cluster_pert),edges,'EdgeColor','none','Normalization','probability');
hold on
h2 = histogram(VisResp_05_15(cluster_rest),edges,'EdgeColor','none','Normalization','probability');
ylabel('Units');
title('All m'); clear Ratios
Ratios(1,:) = [mean(VisResp_05_15(cluster_pert)) std(VisResp_05_15(cluster_pert))/sqrt(sum(cluster_pert)) median(VisResp_05_15(cluster_pert))];
Ratios(2,:) = [mean(VisResp_05_15(cluster_rest)) std(VisResp_05_15(cluster_rest))/sqrt(sum(cluster_rest)) median(VisResp_05_15(cluster_rest))];
legend({['exp. all units, meanratio=' num2str(Ratios(1,1),2) '�' num2str(Ratios(1,2),2) ', median=' num2str(Ratios(1,3),3)]...
        ['nai. all units, meanratio=' num2str(Ratios(2,1),2) '�' num2str(Ratios(2,2),2) ', median=' num2str(Ratios(2,3),3)]})
subplot(3,1,2)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(cluster_pert),VisResp_05_15(cluster_rest)),2)]);
legend({['expi. signrank p=' num2str(signrank(VisResp_05_15(cluster_pert)-1),2)], ...
       ['naive signrank p=' num2str(signrank(VisResp_05_15(cluster_rest)-1),2)]});
subplot(3,1,3)
Data2Plot = [VisResp_05_15(cluster_pert), VisResp_05_15(cluster_rest)];
u_ns = [ones(length(VisResp_05_15(cluster_pert)),1)*1; ...
        ones(length(VisResp_05_15(cluster_rest)),1)*2];
boxplot(Data2Plot,u_ns,'PlotStyle','compact','Colors','rbk','Orientation','horizontal','OutlierSize',1)
xlabel('All mice (exp VS naive)');
ylabel('Transient/Sustained ratio');
set(gca,'TickDir','out','box','off')
xlim([0 4])


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for units of experienced and naive mice
param_sel = AM_Param(:,SelectedCells,:);
Units_Exp = ismember(squeeze(param_sel(1,:,1)),1:37)';
figure
% experienced mice
subplot(3,2,1)
edges = 0:0.1:4;
cluster_pos = Resp_grouping==2 & Units_Exp;
cluster_neg = Resp_grouping==1 & Units_Exp;
cluster_rest = Resp_grouping==0 & Units_Exp;
h1 = histogram(VisResp_05_15(cluster_pos),edges,'EdgeColor','none','Normalization','probability');
hold on
h2 = histogram(VisResp_05_15(cluster_neg),edges,'EdgeColor','none','Normalization','probability');
hold on
h3 = histogram(VisResp_05_15(cluster_rest),edges,'EdgeColor','none','Normalization','probability');
ylabel('Units')
title('Experienced mice'); 
clear Ratios
Ratios(1,:) = [mean(VisResp_05_15(cluster_pos)) std(VisResp_05_15(cluster_pos))/sqrt(sum(cluster_pos)) median(VisResp_05_15(cluster_pos))];
Ratios(2,:) = [mean(VisResp_05_15(cluster_neg)) std(VisResp_05_15(cluster_neg))/sqrt(sum(cluster_neg)) median(VisResp_05_15(cluster_neg))];
Ratios(3,:) = [mean(VisResp_05_15(cluster_rest)) std(VisResp_05_15(cluster_rest))/sqrt(sum(cluster_rest)) median(VisResp_05_15(cluster_rest))];
legend({['MI>0, meanratio=' num2str(Ratios(1,1),2) '�' num2str(Ratios(1,2),2) ', median=' num2str(Ratios(1,3),3)]...
        ['MI<0, meanratio=' num2str(Ratios(2,1),2) '�' num2str(Ratios(2,2),2) ', median=' num2str(Ratios(2,3),3)]...
        ['rest, meanratio=' num2str(Ratios(3,1),2) '�' num2str(Ratios(3,2),2) ', median=' num2str(Ratios(3,3),3)]})
subplot(3,2,3)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
hold on
stairs( (mean(diff(h3.BinEdges))/2)+h3.BinEdges(1:end-1) , h3.Values/sum(h3.Values), 'Color', [0.5 0.5 0.5 ])
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==1 & Units_Exp)),2) ', ' ...
       '(+ vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==0 & Units_Exp)),2) ', ' ...
       '(- vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & Units_Exp),VisResp_05_15(Resp_grouping==0 & Units_Exp)),2)  ]);
legend({['pos. signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==2 & Units_Exp)-1),2)], ...
        ['neg. signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==1 & Units_Exp)-1),2)] ...
        ['rest signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==0 & Units_Exp)-1),2)]});
subplot(3,2,5)
Data2Plot = [VisResp_05_15(cluster_pos), VisResp_05_15(cluster_neg), VisResp_05_15(cluster_rest)];
u_ns = [ones(length(VisResp_05_15(cluster_pos)),1)*1; ...
        ones(length(VisResp_05_15(cluster_neg)),1)*2; ...
        ones(length(VisResp_05_15(cluster_rest)),1)*3];
boxplot(Data2Plot,u_ns,'PlotStyle','compact','Colors','rbk','Orientation','horizontal','OutlierSize',1)
xlabel('Experienced mice');
ylabel('Transient/Sustained ratio');
set(gca,'TickDir','out','box','off')
xlim([0 4])
% naive mice
subplot(3,2,2)
cluster_pos = Resp_grouping==2 & ~Units_Exp;
cluster_neg = Resp_grouping==1 & ~Units_Exp;
cluster_rest = Resp_grouping==0 & ~Units_Exp;
h4 = histogram(VisResp_05_15(cluster_pos),edges,'EdgeColor','none','Normalization','probability');
hold on
h5 = histogram(VisResp_05_15(cluster_neg),edges,'EdgeColor','none','Normalization','probability');
hold on
h6 = histogram(VisResp_05_15(cluster_rest),edges,'EdgeColor','none','Normalization','probability');
ylabel('Units')
title('Naive mice');
clear Ratios
Ratios(1,:) = [mean(VisResp_05_15(cluster_pos)) std(VisResp_05_15(cluster_pos))/sqrt(sum(cluster_pos)) median(VisResp_05_15(cluster_pos))];
Ratios(2,:) = [mean(VisResp_05_15(cluster_neg)) std(VisResp_05_15(cluster_neg))/sqrt(sum(cluster_neg)) median(VisResp_05_15(cluster_neg))];
Ratios(3,:) = [mean(VisResp_05_15(cluster_rest)) std(VisResp_05_15(cluster_rest))/sqrt(sum(cluster_rest)) median(VisResp_05_15(cluster_rest))];
legend({['MI>0, meanratio=' num2str(Ratios(1,1),2) '�' num2str(Ratios(1,2),2) ', median=' num2str(Ratios(1,3),2)]...
        ['MI<0, meanratio=' num2str(Ratios(2,1),2) '�' num2str(Ratios(2,2),2) ', median=' num2str(Ratios(2,3),2)]...
        ['rest, meanratio=' num2str(Ratios(3,1),2) '�' num2str(Ratios(3,2),2) ', median=' num2str(Ratios(3,3),2)]})
subplot(3,2,4)
stairs( (mean(diff(h4.BinEdges))/2)+h4.BinEdges(1:end-1) , h4.Values/sum(h4.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h5.BinEdges))/2)+h5.BinEdges(1:end-1) , h5.Values/sum(h5.Values), 'Color', 'b')
hold on
stairs( (mean(diff(h6.BinEdges))/2)+h6.BinEdges(1:end-1) , h6.Values/sum(h6.Values), 'Color', [0.5 0.5 0.5 ])
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & ~Units_Exp),VisResp_05_15(Resp_grouping==1 & ~Units_Exp)),2) ', ' ...
       '(+ vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & ~Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2) ', ' ...
       '(- vs nr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & ~Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2)  ]);
legend({['pos. signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==2 & ~Units_Exp)-1),2)], ...
        ['neg. signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==1 & ~Units_Exp)-1),2)] ...
        ['rest signrank p=' num2str(signrank(VisResp_05_15(Resp_grouping==0 & ~Units_Exp)-1),2)]});
subplot(3,2,6)
Data2Plot = [VisResp_05_15(cluster_pos), VisResp_05_15(cluster_neg), VisResp_05_15(cluster_rest)];
u_ns = [ones(length(VisResp_05_15(cluster_pos)),1)*1; ...
        ones(length(VisResp_05_15(cluster_neg)),1)*2; ...
        ones(length(VisResp_05_15(cluster_rest)),1)*3];
boxplot(Data2Plot,u_ns,'PlotStyle','compact','Colors','rbk','Orientation','horizontal','OutlierSize',1)
xlabel('Experienced mice');
set(gca,'TickDir','out','box','off')
xlim([0 4])

suptitle(['(X+ vs N+) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==2 & ~Units_Exp)),2) ', ' ... 
       '(X+ vs N-) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==1 & ~Units_Exp)),2) ', ' ...
       '(X+ vs Xnr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2)  ', ' ...
       '(X- vs N+) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & Units_Exp),VisResp_05_15(Resp_grouping==2 & ~Units_Exp)),2) ', ' ...
	   '(X- vs N-) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & Units_Exp),VisResp_05_15(Resp_grouping==1 & ~Units_Exp)),2) ', ' ...
       '(X- vs Nnr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2) ', ' ...
       '(Xnr vs N+) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==0 & Units_Exp),VisResp_05_15(Resp_grouping==2 & ~Units_Exp)),2) ', ' ...
	   '(Xnr vs N-) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==0 & Units_Exp),VisResp_05_15(Resp_grouping==1 & ~Units_Exp)),2) ', ' ...
       '(Xnr vs Nnr) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==0 & Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2) ]);

figure
boxplot(VisResp_05_15(cluster_pos))
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
% for naive vs experienced mice
figure
% positive units
subplot(2,3,1)
edges = 0:0.1:4;
h1 = histogram(VisResp_05_15(Resp_grouping==2 & Units_Exp),edges);
hold on
h2 = histogram(VisResp_05_15(Resp_grouping==2 & ~Units_Exp),edges);
ylabel('Units')
title(['MI>0, n_e=' num2str(sum(Resp_grouping==2 & Units_Exp)) ', (' num2str(sum(Resp_grouping==2 & Units_Exp)/sum(Units_Exp)*100) '%), ' ...
           ', n_n=' num2str(sum(Resp_grouping==2 & ~Units_Exp)) ', (' num2str(sum(Resp_grouping==2 & ~Units_Exp)/sum(~Units_Exp)*100) '%), '])

legend({'Experienced','Naive'})
subplot(2,3,4)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==2 & Units_Exp),VisResp_05_15(Resp_grouping==2 & ~Units_Exp)),2)]);
legend({'Experienced','Naive'})
% negative units
subplot(2,3,2)
edges = 0:0.1:4;
h1 = histogram(VisResp_05_15(Resp_grouping==1 & Units_Exp),edges);
hold on
h2 = histogram(VisResp_05_15(Resp_grouping==1 & ~Units_Exp),edges);
ylabel('Units')
title('MI<0')
legend({'Experienced','Naive'})
subplot(2,3,5)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==1 & Units_Exp),VisResp_05_15(Resp_grouping==1 & ~Units_Exp)),2)]);
legend({'Experienced','Naive'})
% not responding units
subplot(2,3,3)
edges = 0:0.1:4;
h1 = histogram(VisResp_05_15(Resp_grouping==0 & Units_Exp),edges);
hold on
h2 = histogram(VisResp_05_15(Resp_grouping==0 & ~Units_Exp),edges);
ylabel('Units')
title('not responsive')
legend({'Experienced','Naive'})
subplot(2,3,6)
stairs( (mean(diff(h1.BinEdges))/2)+h1.BinEdges(1:end-1) , h1.Values/sum(h1.Values), 'Color', 'r')
hold on
stairs( (mean(diff(h2.BinEdges))/2)+h2.BinEdges(1:end-1) , h2.Values/sum(h2.Values), 'Color', 'b')
set(gca,'box','off','TickDir','out')
ylabel('Fraction of Units')
xlabel('FR_0_._5 / FR_2');
title(['(+ vs -) p=' num2str(ranksum(VisResp_05_15(Resp_grouping==0 & Units_Exp),VisResp_05_15(Resp_grouping==0 & ~Units_Exp)),2)]);
legend({'Experienced','Naive'})


% separate experienced from naive animals
param_sel = AM_Param(:,SelectedCells,:);
Units_Exp_1 = ismember(squeeze(param_sel(1,:,1)),1:11)';
Units_Exp_2 = ismember(squeeze(param_sel(1,:,1)),12:37)';

figure
subplot(2,1,1)
histogram(VisResp_05_15(Units_Exp_1),0:0.1:4)
subplot(2,1,2)
histogram(VisResp_05_15(Units_Exp_2),0:0.1:4)


ranksum(VisResp_05_15(Units_Exp),VisResp_05_15(~Units_Exp))





