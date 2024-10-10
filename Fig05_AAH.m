close all; clear all; clc;
warning off;

%% Annually affected households (AAH)
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';
dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\LuFI\July2023\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))

files = dir([root,'*.tif']);

% Define filter criteria for adaptation
% USE EMPTY f1 FOR EAP
% OR RETURN PERIOD FOR ABS/REL DAMAGE
f1 = '';  % Any return period (e.g. 3h100y)
f2 = 'BC2';     % BC2  = Ring dike
f3 = '15hR';    % 15hR = Rainwater detention
f4 = 'PPM';     % PPM  = private precautionary measures
run = 'casesPPM50-HH\'

%% Choose scenario
PPM = 1; %(yes/no)
% Base Case 2
ind = contains({files(:).name},f1) & contains({files(:).name},f2) & ~contains({files(:).name},f3) & ~contains({files(:).name},f4);
% % Rainwater Detention only
% ind = contains({files(:).name},f1) & contains({files(:).name},f2) & contains({files(:).name},f3) & ~contains({files(:).name},f4);

% See what goes out
clc; disp([num2str(sum(ind)),' file(s) found: '])
format compact; files(ind).name
files(~ind) = []; n=1;

% Sort by new field return period (RP)
for i = 1:length(files)
    files(i).RP = str2num(files(i).name(strfind(files(i).name,'3h')+2:strfind(files(i).name,'y')-1));
end
files = table2struct(sortrows(struct2table(files),'RP'));

% Change crazy casenames
for i=1
    casename = files(1).name(9:end-4);
    casename = replace(casename,'_',' '); % Changed subscript here
    casename = replace(casename,'-',' '); % Changed subscript here
    casename = replace(casename,'(',''); % Changed subscript here
    casename = replace(casename,')',''); % Changed subscript here
    casename = replace(casename,'Res30',''); % Changed subscript here
    casename = replace(casename,'Res90',''); % Changed subscript here
    casename = replace(casename,'V2',''); % Changed subscript here
    casename = replace(casename,'  ',' '); % Changed subscript here
    if PPM ==1
        casename = [casename,'PPM'];
    end
    cname = ['AffPop_W2_',f1,casename(6:end),'_',version];
end

if exist([run,cname,'.mat']) ~= 2
    % Loop over all return periods and calculate EAP
    for f = 1:numel(files)

        % Open ward and results file
        if f==1
            W = shaperead([qgis,'HCMC-districts2_32648.shp']); 
            W2 = shaperead([qgis,'HCMC_population_2019_32648.shp']);
        end
        [A R] = readgeoraster([files(f).folder,'\',files(f).name]);
        [X, Y] = worldGrid(R);

        if PPM == 1
            B = A;      % Households without PPM
            A = A-0.3;  % Households with PPM
            A(A<0) = nan;
        else
            B = A;
        end

        % Analyze inundation maps
        for w = 1:length(W2)

            % Show progress
            clc; n = n + 1;
            N = length(W2)*length(files);
            disp(['Ward ',num2str(n),'/',num2str(N),' processed...'])

            % Find number of affected cells per Ward
            ind = dsearchn([W(:).Area]',W2(w).DistArea);
            W2(w).District = W(ind).NAME_2; clear ind;

            W2(w).RP(f) = files(f).RP;
            ind = inpolygon(X,Y,W2(w).X,W2(w).Y);
            W2(w).NCells(f) = numel(A(ind));
            W2(w).NFloodA(f) = sum(A(ind)>0.1);
            W2(w).NFloodB(f) = sum(B(ind)>0.1);
            W2(w).PFloodA(f) = W2(w).NFloodA(f) / W2(w).NCells(f);
            W2(w).PFloodB(f) = W2(w).NFloodB(f) / W2(w).NCells(f);
            W2(w).PFlood(f) = mean([W2(w).PFloodA(f),W2(w).PFloodB(f)]);
            W2(w).AffPopA(f) = W2(w).PFloodA(f) * W2(w).Population;
            W2(w).AffPopB(f) = W2(w).PFloodB(f) * W2(w).Population;
            W2(w).AffPop(f) = mean([W2(w).AffPopA(f),W2(w).AffPopB(f)]);
            W2(w).AffHH(f) = W2(w).AffPop(f) ./ W2(w).Persons_hh;

        end
    end

    % Save scenario to cases folder
    save([run,cname],'W2','W')

else
    load([run,cname])
end

%% Calculate Expected annual population (EAP) and Expected total population (area below curve)
scen = casename(6:end);

for w = 1:length(W2)
    W2(w).HH = W2(w).Population / W2(w).Persons_hh;
    W2(w).EAP = trapz(flip(1./W2(w).RP),flip(W2(w).AffPop)) ;
    W2(w).EAH = trapz(flip(1./W2(w).RP),flip(W2(w).AffHH)) ;
    W2(w).EAPpP = W2(w).EAP / W2(w).Population * 100;
    W2(w).EAHpP = W2(w).EAH / W2(w).HH * 100;
end

for w = 1:numel(W2)
    % Find and aggregate EAP by district
    Dists = {W2(:).District};
    ind = strcmp(Dists,W2(w).District);

    W2(w).DistEAP = sum([W2(ind).EAP]);
    W2(w).DistPop = sum([W2(ind).Population]);
    W2(w).DistEAPpP = W2(w).DistEAP / W2(w).DistPop * 100;

    W2(w).DistEAH = sum([W2(ind).EAH]);
    W2(w).DistHH = sum([W2(ind).HH]);
    W2(w).DistEAHpP = W2(w).DistEAP / W2(w).DistHH * 100;
end

% Fill district table W with aggregates
for w = 1:numel(W)
    ind = strcmp(Dists,W(w).NAME_2);
    ind2 = find(ind==1);
    W(w).District = W2(ind2(1)).District;

    W(w).DistEAP = W2(ind2(1)).DistEAP;
    W(w).DistPop = W2(ind2(1)).DistPop;
    W(w).DistEAPpP = W2(ind2(1)).DistEAPpP;

    W(w).DistEAH = W2(ind2(1)).DistEAH;
    W(w).DistHH = W2(ind2(1)).DistHH;
    W(w).DistEAHpP = W2(ind2(1)).DistEAHpP;
end

if contains(casename,f2) & ~contains(casename,f3) & ~contains(casename,f4)
    save([run,'AffPop_W2_BaseCase2_',version,'.mat'],'W2','W2','W')
end
save([run,cname],'W2','W')

%% Plot example curve
close all;
figure; hold on; box on;
AbsD = plot(mean(vertcat(W2(:).RP)),sum(vertcat(W2(:).AffPop) / 1e6) ,'k','LineWidth',1.5);  % CHANGED TO SUM HERE
EAP = yline(sum([W2(:).EAP]) ./ 1e6,'--'); % CHANGED TO SUM HERE
text(0.7,0.05,['EAP = ',sprintf('%0.3f',sum([W2(:).EAP]./ 1e6)),' Mio',''],'units','normalized');  % CHANGED TO SUM HERE
lgd = legend([AbsD,EAP],'Mio. affected people','Exp. annual average','Location','northwest');
xlabel('Return period (years)'); xticks([W2(1).RP]);
xlim([1 100]); ylim([0 5])
ylabel('Mio. affected people');
title({['HCMC flood risk (', scen,')'],''},'FontWeight','normal');
set(gcf,'Color','white');

% Print to file (could be copied anywhere after installing export_fig)
dpi = '300';
pname = [dtop,'Fig01-HCMC-meanEAP_',scen];
% export_fig([pname,'RiskCuveEAP_',scen,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

%% Show choropleth for EAP (annually affected people)
load([run,cname])
% Load and define colormap
N = 9; FA = 0.5; FS = 7;
load('lajolla.mat');
lajolla = downsample(lajolla,round(length(lajolla)/N)); lajolla = lajolla(2:end-1,:);

W3 = W2;

% Open figure and project
figure; grid on;
s1 = subplot(2,1,1);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6500   10.9500],"MapLonLimit",[106.5500  106.9000])

for d = 1:numel(W2)
    W2(d).EAH = W2(d).EAH ./ 1e3;
    W2(d).DistEAH = W2(d).DistEAH ./ 1e3;
end

[~, orderEAH] = sort([W.DistEAH], 'descend');

maxD = 8; %max([W2.EAP]); %EXAMPLE OF RIGID THRESHOLD
ind = find([W2.EAH] > maxD);
if ~isempty(ind)
    [W2(ind).EAH] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"EAH",[0 maxD],"FaceColor",lajolla,"EdgeColor",[0.5 0.5 0.5]});
geoshow(W2,"SymbolSpec",polyColors)
colormap(lajolla); clim([0 maxD]);
cb = colorbar; set(cb,'YTick',0:2:8); 

% Beautify plot
dike = shaperead([root(1:42),'QGIS\RingDike_32648.shp']); 
DIKE = patch(dike.X,dike.Y,[0.25 0.25 0.25],'FaceAlpha',0,'LineWidth',2,'EdgeColor',[0.25 0.25 0.25]);
axis padded
xticks(106.5:0.1:106.9);
xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9);
ytickformat('%.2f\x00B0 N');
ytickangle(90)
title({['     AAH in thousand households (10^3 HH.)'],''},'FontWeight','normal')
text(0.83,0.13,{'AAH_{tot}',[sprintf('%0.0f',sum([W(:).DistEAH]./1e3)),' \times10^3 HH.']}, ...
    'units','normalized','FontSize',FS,'HorizontalAlignment','center');

% Add districts
for d = 1:numel(W)
    patch((W(d).X),(W(d).Y),'w','FaceAlpha',0,'EdgeColor',[0.5 0.5 0.5],'LineWidth',0.5)
end
set(gcf,'Color','white');

%% Add ranking
for i = 1:3
    sq(i) = plot(mean((W(orderEAH(i)).X),'omitnan'), mean((W(orderEAH(i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5);
    sq(i+3) = plot(mean((W(orderEAH(end-3+i)).X),'omitnan'), mean((W(orderEAH((end-3+i))).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5);
    t(i) = text(mean((W(orderEAH(i)).X),'omitnan'), mean((W(orderEAH(i)).Y),'omitnan'), num2str(i),'color','black','FontWeight','normal','FontSize',8,'HorizontalAlignment','center','VerticalAlignment','middle');
    t(i+3) = text(mean((W(orderEAH(end-3+i)).X),'omitnan'), mean((W(orderEAH((end-3+i))).Y),'omitnan'), num2str(16+i) ,'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
    text(i, -0.5*maxD , W(orderEAH(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
    text(4+i, -0.5*maxD , W(orderEAH(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
    p(i) = patch((W(orderEAH(i)).X),(W(orderEAH(i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
    p(i+3) = patch((W(orderEAH(end-3+i)).X),(W(orderEAH(end-3+i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
end

uistack(sq,'top');
uistack(t,'top');

% Now using district table W
s2 = subplot(2,1,2);
maxD = 80; % max([W(:).DistEAH])

bar(1:3,[W(orderEAH(1:3)).DistEAH] ./ 1e3,'facecolor',[214/256 103/256 78/256]); hold on;
bar(5:7,[W(orderEAH(end-2:end)).DistEAH] ./1e3,'facecolor',[214/256 103/256 78/256]); hold on;
box off
title('')
set(gcf,'Color','white');
xlim([0 8]); ylim([0 3*maxD]);
set(s2,'position',[0.269047619047619,0.35,0.4045,0.2])
set(s2,'YAxisLocation','right')

text(1:3, ones(1,3)*2.5*maxD, {'1','2','3'} ,'color','black','FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
text(5:7, ones(1,3)*2.5*maxD, {'17','18','19'} ,'color','black','FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
plot(1:3, ones(1,3)*2.5*maxD,'k','MarkerSize',FS+3,'Marker','square','LineWidth',0.5,'LineStyle','none');
plot(5:7, ones(1,3)*2.5*maxD,'k','MarkerSize',FS+3,'Marker','square','LineWidth',0.5,'LineStyle','none');
for i = 1:3
    text(i, [W(orderEAH(i)).DistEAH]/1e3,sprintf('%0.0f',W(orderEAH(i)).DistEAH/1e3),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',FS);
    text(4+i, [W(orderEAH(end-3+i)).DistEAH]/1e3,sprintf('%0.0f',W(orderEAH(end-3+i)).DistEAH/1e3),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',FS);
    text(i, -0.5*maxD , W(orderEAH(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
    text(4+i, -0.5*maxD , W(orderEAH(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
end
set(s2,'YColor','w')

% Print to file 
dpi = '300';
fname = files(1).name(14:end);
pname = [dtop,'AAH-Distribution_',scen];
% export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

% Write shape file
fields = fieldnames(W2);
for ff = 18:28
    W2 = rmfield(W2,fields(ff));
end

shapefolder = 'C:\Users\scheiber\Desktop\Scheiber et al. 2024\AAHs\';
shapename = [shapefolder,'AAH_',casename(6:end),'.shp'];
shapewrite(W2,shapename)

W2 = W3;
