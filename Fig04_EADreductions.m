close all; clear all; clc;

%% Fig 4: EAD reductions
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';
dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\GFZ\',version,'\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))

files = dir([root,'*.shp']);

% Define filter criteria for adaptation
% USE EMPTY f1 FOR EAD
% OR RETURN PERIOD FOR ABS/REL DAMAGE
f1 = '';  % Any return period (e.g. 3h100y)
f2 = 'BC2';     % BC2 = Ring dike
f3 = '15hR';    % 15hR = Rainwater detention
f4 = 'PPM'; % no_elev = no private precautionary measures
run = 'casesPPM50';

%% Choose scenario
% Base Case 2
% ind = contains({files(:).name},f1) & contains({files(:).name},f2) & ~contains({files(:).name},f3) & ~contains({files(:).name},f4);
% Private Precaution only
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
close all;
dike = shaperead([root(1:42),'QGIS\RingDike4326.shp']);
load([run,'\D2_',casename(6:end),'_',version,'.mat'])
D_adapt = D2;
W_adapt = W;
clear D2 W

load([run,'\D2_BaseCase2_',version,'.mat'])
D_base = D2;
W_base = W;
% clear D2

% Calculate EAD reductions per ward
for w = 1:numel(D_adapt)
    D2(w).DistPop = D_adapt(w).DistPop;

    D2(w).EADred = (D_adapt(w).EAD - D_base(w).EAD) ./ 1e6;
    D2(w).EADredL = (D_adapt(w).EADL - D_base(w).EADL) ./ 1e6;
    D2(w).EADredH = (D_adapt(w).EADH - D_base(w).EADH) ./ 1e6;
    D2(w).DistEADred = (D_adapt(w).DistEAD - D_base(w).DistEAD) ./ 1e6;
    D2(w).DistEADredL = (D_adapt(w).DistEADL - D_base(w).DistEADL) ./ 1e6;
    D2(w).DistEADredH = (D_adapt(w).DistEADH - D_base(w).DistEADH) ./ 1e6;

    D2(w).EADred_PP = (D_adapt(w).EAD - D_base(w).EAD) ./ D2(w).Population;
    D2(w).EADredL_PP = (D_adapt(w).EADL - D_base(w).EADL) ./ D2(w).Population;
    D2(w).EADredH_PP = (D_adapt(w).EADH - D_base(w).EADH) ./ D2(w).Population;
    D2(w).DistEADred_PP = (D_adapt(w).DistEAD - D_base(w).DistEAD) ./ D2(w).DistPop;
    D2(w).DistEADredL_PP = (D_adapt(w).DistEADL - D_base(w).DistEADL) ./ D2(w).DistPop;
    D2(w).DistEADredH_PP = (D_adapt(w).DistEADH - D_base(w).DistEADH) ./ D2(w).DistPop;
end

% Fill district table W with aggregates
for w = 1:numel(W)
    W(w).DistEADred = (W_adapt(w).DistEAD - W_base(w).DistEAD) ./ 1e6;
    W(w).DistEADredL = (W_adapt(w).DistEADL - W_base(w).DistEADL) ./ 1e6;
    W(w).DistEADredH = (W_adapt(w).DistEADH - W_base(w).DistEADH) ./ 1e6;

    W(w).DistEADred_PP = (W_adapt(w).DistEAD - W_base(w).DistEAD) ./ W(w).DistPop;
    W(w).DistEADredL_PP = (W_adapt(w).DistEADL - W_base(w).DistEADL) ./ W(w).DistPop;
    W(w).DistEADredH_PP = (W_adapt(w).DistEADH - W_base(w).DistEADH) ./ W(w).DistPop;    
end

%% Show ward/district reductions of EAD
% Load and define colormap
close all;
N =  9; FA = 0.5; FS = 7;
load('vik.mat'); vik = downsample(vik,round(length(vik)/N)); vik = vik(2:end-1,:); %vik = [vik(1:6,:);[1 1 1];vik(7:end,:)];

D3 = D2;

% Open figure and project
figure; grid on;
s1 = subplot(2,1,1);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6500   10.9500],"MapLonLimit",[106.5500  106.9000])

[~, orderEAD] = sort([W.DistEADred], 'descend');

minD = -4; %max([D2.EAD]); %EXAMPLE OF RIGID THRESHOLD
maxD = 4; %max([D2.EAD]); %EXAMPLE OF RIGID THRESHOLD
mind = find([D2.EADred] < minD);
maxd = find([D2.EADred] > maxD);
if ~isempty(mind)
    [D2(mind).EADred] = deal(minD);
end
if ~isempty(maxd)
    [D2(maxd).EADred] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"EADred",[minD maxD],"FaceColor",vik,"EdgeColor",[0.5 0.5 0.5]});
geoshow(D2,"SymbolSpec",polyColors)
colormap(vik); clim([minD maxD]);
cb = colorbar;
cb.YTick = -4:2:4;
cb.YTickLabel = {'-4','-2','0','+2','+4'};

% Beautify plot
DIKE = patch(dike.X,dike.Y,[0.25 0.25 0.25],'FaceAlpha',0,'LineWidth',2,'EdgeColor',[0.25 0.25 0.25]);
axis padded; %grid on;
xticks(106.5:0.1:106.9);
xticklabels('')
yticks(10.7:0.1:10.9);
yticklabels('')
    title({['\DeltaEAD in Million dollars (10^6 $)'],''},'FontWeight','normal')
text(0.84,0.13,{'\DeltaEAD_{tot}',[sprintf('%0.1f',sum([D2(:).EADred])),' \times10^6 $']}, ...
    'units','normalized','FontSize',FS,'HorizontalAlignment','center');

% Add districts
for d = 1:numel(W)
    patch((W(d).X),(W(d).Y),'w','FaceAlpha',0,'EdgeColor',[0.5 0.5 0.5],'LineWidth',1)
end
set(gcf,'Color','white');


for i = 1:3
    sq(i) = plot(mean((W(orderEAD(i)).X),'omitnan'), mean((W(orderEAD(i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    sq(i+3) = plot(mean((W(orderEAD(end-3+i)).X),'omitnan'), mean((W(orderEAD((end-3+i))).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    t(i) = text(mean((W(orderEAD(i)).X),'omitnan'), mean((W(orderEAD(i)).Y),'omitnan'), [num2str((numel(W)+1-i)),''],'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    t(i+3) = text(mean((W(orderEAD(end-3+i)).X),'omitnan'), mean((W(orderEAD((end-3+i))).Y),'omitnan'), [num2str(4-i),''] ,'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    p(i) = patch((W(orderEAD(i)).X),(W(orderEAD(i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
    p(i+3) = patch((W(orderEAD(end-3+i)).X),(W(orderEAD(end-3+i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
end

uistack(sq,'top'); 
uistack(t,'top'); 

s2 = subplot(2,1,2);

minD = -40; %max([W.DistEADred]); %EXAMPLE OF RIGID THRESHOLD
maxD = 40; %max([W.DistEADred]); %EXAMPLE OF RIGID THRESHOLD

% Flop 3
if W(orderEAD(1)).DistEADred < 0
    bar(1:3,[W(orderEAD(1:3)).DistEADred],'facecolor',[167/256 201/256 218/256]); hold on;
else
    bar(1:3,[W(orderEAD(1:3)).DistEADred],'facecolor',[214/256 103/256 78/256]); hold on;
end

% Top 3
bar(5:7,[W(orderEAD(end-2:end)).DistEADred],'facecolor',[167/256 201/256 218/256]); hold on;

% Beautify plot sheet
xticks(1:7); xticklabels({W(orderEAD(1:3)).District,' ',W(orderEAD(end-2:end)).District});
box off
title('')
set(gcf,'Color','white');
ylabel({' ','EAD change (Mio $)'},'FontSize',FS);
xlim ([0 8])
ylim([1*minD 1*maxD]); %yticks([0 5])
set(s2,'position',[0.269047619047619,0.35,0.4045,0.2])
set(s2,'YAxisLocation','right')
axis off

% Add ranking
oy = 0.6;
for i = 1:3

    %     if D3(orderEAD(i)).EADred < 0
    plot(i, oy*maxD, 'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    text(i, oy*maxD, [num2str(20-i),''],'color',[0 0 0],'FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
    text(i, [W(orderEAD(i)).DistEADred] , sprintf('%0.2f',W(orderEAD(i)).DistEADred) ,'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(i, 1*minD , W(orderEAD(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);

    plot(4+i, oy*maxD, 'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    text(4+i, oy*maxD, [num2str(4-i),''] ,'color',[0 0 0],'FontWeight','normal','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    text(4+i, [W(orderEAD(end-3+i)).DistEADred] , sprintf('%0.2f',W(orderEAD(end-3+i)).DistEADred),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(4+i, 1.4*minD , W(orderEAD(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
end

set(s2,'XDir','reverse')

% Print to file (could be copied anywhere after installing export_fig)
dpi = '300';
fname = files(1).name(14:end);
pname = [dtop,'EAD-changes_',scen];
export_fig([pname,datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

D2 = D3;
