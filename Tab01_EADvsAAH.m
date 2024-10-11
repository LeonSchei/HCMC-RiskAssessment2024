close all; clear; clc;

%% Expected annual damage per affected household (EAD/AAH)
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';

dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\GFZ\',version,'\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))
C = shaperead([qgis,'HCMC_4326.shp']); 
D = shaperead([qgis,'HCMC-districts2_4326.shp']); 

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
dike = shaperead([root(1:42),'QGIS\RingDike4326.shp']);
load([run,'AffPop_W2_',casename(6:end),'_',version,'.mat'])
W_adapt = W;
W2_adapt = W2;
load([run,'D2_',casename(6:end),'_',version,'.mat'])
D2_adapt = D2;
[W2_adapt(:).EAD] = deal(D2.EAD);
[W2_adapt(:).DistEAD] = deal(D2.DistEAD);
[W_adapt(:).DistEAD] = deal(W.DistEAD);
[W2_adapt.X] = deal(D2_adapt.X);
[W2_adapt.Y] = deal(D2_adapt.Y);
[W_adapt.X] = deal(W.X);
[W_adapt.Y] = deal(W.Y);
clear D2 W2 W

load([run,'AffPop_W2_BaseCase2_',version,'.mat'])
W_base = W;
W2_base = W2;
load([run,'D2_BaseCase2_',version,'.mat'])
D2_base = D2;
[W2_base(:).EAD] = deal(D2.EAD);
[W2_base(:).DistEAD] = deal(D2.DistEAD);
[W_base(:).DistEAD] = deal(W.DistEAD);

% Calculate EAH reductions per ward
for w = 1:numel(W2_adapt)
     
    W2_adapt(w).EADvEAH = (W2_adapt(w).EAD / W2_base(w).EAH);
    W2_adapt(w).DistEADvEAH = (W2_adapt(w).DistEAD ./ W2_base(w).DistEAH);

    W2_base(w).EADvEAH = (W2_base(w).EAD ./ W2_base(w).EAH);
    W2_base(w).DistEADvEAH = (W2_base(w).DistEAD ./ W2_base(w).DistEAH);

    [W2(w).X] = [D2_adapt(w).X];
    [W2(w).Y] = [D2_adapt(w).Y];
    
    W2(w).EADvEAHred = (W2_adapt(w).EADvEAH - W2_base(w).EADvEAH);
    W2(w).DistEADvEAHred = (W2_adapt(w).DistEADvEAH - W2_base(w).DistEADvEAH);

end

% Fill district table W with aggregates
for w = 1:numel(W_adapt)
%   Same as above
    W_adapt(w).DistEADvEAH = (W_adapt(w).DistEAD ./ W_base(w).DistEAH);
    W_base(w).DistEADvEAH = (W_base(w).DistEAD ./ W_base(w).DistEAH);
    W(w).DistEADvEAHred = (W_adapt(w).DistEADvEAH - W_base(w).DistEADvEAH);
end

%% Show ward/district reductions of EAH
% Load and define colormap
N = 9; FA = 0.5; FS = 7;
load('vik.mat'); vik = downsample(vik,round(length(vik)/N)); vik = vik(2:end-1,:); %vik = [vik(1:6,:);[1 1 1];vik(7:end,:)];

W3 = W2;

% Open figure and project
figure; grid on;
s1 = subplot(2,1,1);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6500   10.9500],"MapLonLimit",[106.5500  106.9000])

[~, orderEAH] = sort([W.DistEADvEAHred], 'ascend');

minD = -800; %min([W2.EADvEAHred]); %EXAMPLE OF RIGID THRESHOLD
maxD =  800; %max([W2.EADvEAHred]); %EXAMPLE OF RIGID THRESHOLD
mind = find([W2.EADvEAHred] < minD);
maxd = find([W2.EADvEAHred] > maxD);
if ~isempty(mind)
    [W2(mind).EADvEAHred] = deal(minD);
end
if ~isempty(maxd)
    [W2(maxd).EADvEAHred] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"EADvEAHred",[minD maxD],"FaceColor",vik,"EdgeColor",[0.5 0.5 0.5]});
geoshow(W2,"SymbolSpec",polyColors)
colormap(vik); clim([minD maxD]);
cb = colorbar; 
cb.FontSize = FS;
cb.YTick = [-800:400:800];

% Beautify plot
DIKE = patch(dike.X,dike.Y,[0.25 0.25 0.25],'FaceAlpha',0,'LineWidth',2,'EdgeColor',[0.25 0.25 0.25]);
axis padded
xticks(106.5:0.1:106.9);
xtickformat('%.1f\x00B0 E');
xticklabels([])
yticks(10.7:0.1:10.9);
ytickformat('%.1f\x00B0 N');
ytickangle(90)
yticklabels([])
title({['\DeltaEAD/AAH in $/HH'],''},'FontWeight','normal')
text(0.85,0.13,{'\DeltaEAD_{mean}',[sprintf('%0.0f',mean([W(:).DistEADvEAHred])),' $/HH']}, ...
    'units','normalized','FontSize',FS,'HorizontalAlignment','center');

% Add districts
for d = 1:numel(D)
    patch((D(d).X),(D(d).Y),'w','FaceAlpha',0,'EdgeColor',[0.75 0.75 0.75],'LineWidth',0.5)
end
set(gcf,'Color','white');

% Add ranking to map
for i = 1:3
    sq(i) = plot(mean((W_adapt(orderEAH(i)).X),'omitnan'), mean((W_adapt(orderEAH(i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',11,'LineWidth',1);
    t(i) = text(mean((W_adapt(orderEAH(i)).X),'omitnan'), mean((W_adapt(orderEAH(i)).Y),'omitnan'), [num2str(i),''],'color','black','FontWeight','normal','FontSize',8,'HorizontalAlignment','center','VerticalAlignment','middle');
    p(i) = patch(W(orderEAH(i)).X, W(orderEAH(i)).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',1);
    
    sq(i+3) = plot(mean((W_adapt(orderEAH(16+i)).X),'omitnan'), mean((W_adapt(orderEAH(16+i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',11,'LineWidth',1);
    t(i+3) = text(mean((W_adapt(orderEAH(16+i)).X),'omitnan'), mean((W_adapt(orderEAH(16+i)).Y),'omitnan'), [num2str(16+i),''],'color','black','FontWeight','normal','FontSize',8,'HorizontalAlignment','center','VerticalAlignment','middle');
    p(i+3) = patch(W(orderEAH(16+i)).X, W(orderEAH(16+i)).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',1);
end
uistack(sq,'top'); 
uistack(t,'top'); 

% Add ranking
s2 = subplot(2,1,2);

minD = -800; %min([W.DistEADvEAHred]); %EXAMPLE OF RIGID THRESHOLD
maxD =  0; %max([W.DistEADvEAHred]); %EXAMPLE OF RIGID THRESHOLD
% Top 5
bar(1:3,[W(orderEAH(1:3)).DistEADvEAHred],'facecolor',[167/256 201/256 218/256]); hold on;
bar(5:7,[W(orderEAH(17:19)).DistEADvEAHred],'facecolor',[167/256 201/256 218/256]); hold on;

xticks(1:5); xticklabels({W(orderEAH(1:5)).District});
box off
title('')
set(gcf,'Color','white');
ylabel({' ','EAH change ($/HH.)'},'FontSize',FS);
xlim ([0 8])
ylim([minD -0.25*minD]); %yticks([0 5])
set(s2,'position',[0.269047619047619,0.32,0.4045,0.2])
set(s2,'YAxisLocation','right')
axis off

% Add annotations
oy = -0.25;
for i = 1:3
    plot(i, oy*minD,'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    plot(4+i, oy*minD,'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
    text(i, oy*minD, [num2str(i),''],'color',[0 0 0],'color','black','FontWeight','normal','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    text(4+i, oy*minD, [num2str(16+i),''],'color',[0 0 0],'color','black','FontWeight','normal','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    text(i, [W(orderEAH(i)).DistEADvEAHred] , sprintf('%0.0f',W(orderEAH(i)).DistEADvEAHred ) ,'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(4+i, [W(orderEAH(16+i)).DistEADvEAHred] , sprintf('%0.0f',W(orderEAH(16+i)).DistEADvEAHred ) ,'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','top','FontSize',FS);
    text(i, 0.8*minD , W(orderEAH(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
    text(4+i, 0.8*minD , W(orderEAH(16+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
end

% Print to file 
dpi = '300';
fname = files(1).name(14:end);
pname = [dtop,'EADvsAAH-changes_',scen];
export_fig([pname,datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

W2 = W3;
