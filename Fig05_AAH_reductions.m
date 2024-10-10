close all; clear; clc;

%% Annually affected households (AAH)
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';

dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\GFZ\',version,'\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))

files = dir([root,'*.shp']);

% Define filter criteria for adaptation
% USE EMPTY f1 FOR EAH
f1 = '';  % Any return period (e.g. 3h100y)
f2 = 'BC2';     % BC2 = Ring dike
f3 = '15hR';    % 15hR = Rainwater detention
f4 = 'PPM'; % no_elev = no private precautionary measures
run = 'casesPPM50-HH\';

%% Choose scenario
% Base Case 2
% ind = contains({files(:).name},f1) & contains({files(:).name},f2) & ~contains({files(:).name},f3) & ~contains({files(:).name},f4);
% % Private Precaution only
% ind = contains({files(:).name},f1) & contains({files(:).name},f2) & ~contains({files(:).name},f3) & contains({files(:).name},f4);
% % Rainwater Detention only
% ind = contains({files(:).name},f1) & contains({files(:).name},f2) & contains({files(:).name},f3) & ~contains({files(:).name},f4);
% % Combination of PPM and 15hR
ind = contains({files(:).name},f1) & contains({files(:).name},f2) & contains({files(:).name},f3) & contains({files(:).name},f4);

% See what goes out
clc; disp([num2str(sum(ind)),' file(s) found: '])
format compact; files(ind).name
files(~ind) = [];

%% Change crazy casenames
casename = files(1).name(9:end-4);
casename = replace(casename,'_',' '); % Changed subscript here
casename = replace(casename,'-',' '); % Changed subscript here
casename = replace(casename,'(',''); % Changed subscript here
casename = replace(casename,')',''); % Changed subscript here
casename = replace(casename,'Res30',''); % Changed subscript here
casename = replace(casename,'Res90',''); % Changed subscript here
casename = replace(casename,'V2',''); % Changed subscript here
casename = replace(casename,'  ',' '); % Changed subscript here
scen = casename(6:end);

%% Load ward level adaptation
clc; close all;
dike = shaperead([root(1:42),'QGIS\RingDike_32648.shp']); % Note that theres a Ring_dike file as well
load([run,'AffPop_W2_',casename(6:end),'_',version,'.mat'])
W_adapt = W;
W2_adapt = W2;
clear W2 W

load([run,'AffPop_W2_BaseCase2_',version,'.mat'])
W_base = W;
W2_base = W2;
% clear W2

% Calculate EAH reductions per ward
for w = 1:numel(W2_adapt)
    W2(w).DistPop = W2_adapt(w).DistPop;
    W2(w).DistHH = W2_adapt(w).DistHH;
    W2(w).EAHred = (W2_adapt(w).EAH - W2_base(w).EAH) ./ 1e3;
    W2(w).DistEAHred = (W2_adapt(w).DistEAH - W2_base(w).DistEAH) ./ 1e3;

    W2(w).EAHred_PP = (W2_adapt(w).EAH - W2_base(w).EAH) ./ W2(w).Population * 100;
    W2(w).DistEAHred_PP = (W2_adapt(w).DistEAH - W2_base(w).DistEAH) ./ W2(w).DistPop * 100;
end

% Fill district table W with aggregates
for w = 1:numel(W_adapt)
    W(w).DistEAHred = (W_adapt(w).DistEAH - W_base(w).DistEAH) ./ 1e3;
    W(w).DistEAHred_PP = (W_adapt(w).DistEAH - W_base(w).DistEAH) ./ W(w).DistPop * 100;
end

%% Show ward/district reductions of EAH
% Load and define colormap
close all;
N =  9; FA = 0.5; FS = 7;
load('vik.mat'); vik = downsample(vik,round(length(vik)/N)); vik = vik(2:end-1,:); %vik = [vik(1:6,:);[1 1 1];vik(7:end,:)];

W3 = W2;

% Open figure and project
figure; grid on;
s1 = subplot(2,1,1);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6500   10.9500],"MapLonLimit",[106.5500  106.9000])

[~, orderEAH] = sort([W.DistEAHred], 'descend');
minD = -8; %min([W2.EAHred]); %EXAMPLE OF RIGID THRESHOLD
maxD =  8; %max([W2.EAHred]); %EXAMPLE OF RIGID THRESHOLD
mind = find([W2.EAHred] < minD);
maxd = find([W2.EAHred] > maxD);
if ~isempty(mind)
    [W2(mind).EAHred] = deal(minD);
end
if ~isempty(maxd)
    [W2(maxd).EAHred] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"EAHred",[minD maxD],"FaceColor",vik,"EdgeColor",[0.5 0.5 0.5]});
geoshow(W2,"SymbolSpec",polyColors)
colormap(vik); clim([minD maxD]);
cb = colorbar; 
cb.YTick = [-8:4:8];
cb.YTickLabel = {'-8','-4','0','+4','+8'};

% Beautify plot
DIKE = patch(dike.X,dike.Y,[0.25 0.25 0.25],'FaceAlpha',0,'LineWidth',2,'EdgeColor',[0.25 0.25 0.25]);
axis padded
xticks(106.5:0.1:106.9);
xticklabels('')
yticks(10.7:0.1:10.9);
yticklabels('')
title({['     \DeltaAAH in thousand households (10^3 HH.)'],''},'FontWeight','normal')
text(0.83,0.13,{'\DeltaAAH_{tot}',[sprintf('%0.0f',sum([W2(:).EAHred])),' \times10^3 HH.']}, ...
    'units','normalized','FontSize',FS,'HorizontalAlignment','center');

% Add districts
for d = 1:numel(W)
    patch((W(d).X),(W(d).Y),'w','FaceAlpha',0,'EdgeColor',[0.5 0.5 0.5],'LineWidth',1)
end
set(gcf,'Color','white');

% Add ranking
for i = 1:3
    sq(i) = plot(mean((W(orderEAH(i)).X),'omitnan'), mean((W(orderEAH(i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5);
    sq(i+3) = plot(mean((W(orderEAH(end-3+i)).X),'omitnan'), mean((W(orderEAH((end-3+i))).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5);
    t(i) = text(mean((W(orderEAH(i)).X),'omitnan'), mean((W(orderEAH(i)).Y),'omitnan'), num2str((numel(W)+1-i)),'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    t(i+3) = text(mean((W(orderEAH(end-3+i)).X),'omitnan'), mean((W(orderEAH((end-3+i))).Y),'omitnan'), num2str(4-i) ,'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    p(i) = patch((W(orderEAH(i)).X),(W(orderEAH(i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
    p(i+3) = patch((W(orderEAH(end-3+i)).X),(W(orderEAH(end-3+i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
end

uistack(sq,'top');
uistack(t,'top');

s2 = subplot(2,1,2);

minD = -80; %max([W.DistEAHred]); %EXAMPLE OF RIGID THRESHOLD
maxD =  80; %max([W.DistEAHred]); %EXAMPLE OF RIGID THRESHOLD
% Flop 3
if W(orderEAH(1)).DistEAHred < 0
    bar(1:3,[W(orderEAH(1:3)).DistEAHred],'facecolor',[167/256 201/256 218/256]); hold on;
else
    bar(1:3,[W(orderEAH(1:3)).DistEAHred],'facecolor',[214/256 103/256 78/256]); hold on;
end

% Top 3
bar(5:7,[W(orderEAH(end-2:end)).DistEAHred],'facecolor',[167/256 201/256 218/256]); hold on;

xticks(1:7); xticklabels({W(orderEAH(1:3)).District,' ',W(orderEAH(end-2:end)).District});
box off
title('')
set(gcf,'Color','white');
ylabel({' ','EAH change (Mio $)'},'FontSize',FS);
xlim ([0 8])
ylim([1*minD 1*maxD]); 
set(s2,'position',[0.269047619047619,0.35,0.4045,0.2])
set(s2,'YAxisLocation','right')
axis off

% Beautify plot
for i = 1:3
    plot(i, 0.5*maxD, 'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    text(i, 0.5*maxD, num2str(20-i),'color',[0 0 0],'FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
    text(i, [W(orderEAH(i)).DistEAHred] , sprintf('%0.0f',W(orderEAH(i)).DistEAHred ) ,'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(i, 1*minD , W(orderEAH(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);

    plot(4+i, 0.5*maxD, 'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    text(4+i, 0.5*maxD, num2str(4-i) ,'color',[0 0 0],'FontWeight','normal','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    text(4+i, [W(orderEAH(end-3+i)).DistEAHred] , sprintf('%0.0f',W(orderEAH(end-3+i)).DistEAHred ),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(4+i, 1*minD , W(orderEAH(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
end

set(s2,'XDir','reverse')

% Print to file 
dpi = '300';
fname = files(1).name(14:end);
pname = [dtop,'AAP-changes_',scen];
export_fig([pname,datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

W2 = W3;
