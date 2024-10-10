close all; clear all; clc;

%% Fig. 3: Risk Components
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';
dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\GFZ\',version,'\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))

% Load district/ward data
C = shaperead([qgis,'HCMC_4326.shp']);
D = shaperead([qgis,'HCMC-districts2_4326.shp']);
W = shaperead([qgis,'HCMC-wards_4326.shp']);

FS = 12;
LW = 1;

%% HAZARD mapping
[Z R] = geotiffread([dtop,'Risk Assessment\Hazard\BC2_3h100y_4326.tif']);
[X Y] =  geographicGrid(R); 

% Plot point data as (filled) scatter
close all
figure; hold on; box on;
set(gca,'FontSize',FS);
pcolor(Y,X,Z);
shading interp; daspect([1 1 1]);
load('devon.mat'); N = 9;
devon = downsample(devon,round(length(devon)/N));
colormap(flip(devon)); cbs = colorbar; set(cbs,'Location','EastOutside');
cbs.Label.String = 'Flood Depth (m)'; cbs.FontSize = FS;
clim([0.0 0.5]); cbs.Ticks  = [0:0.1:0.5];

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add km scale
dz = 0.003; dx = 0.11;
o1 = [10.703,106.6586+dx];
o2 = [10.703 106.7043+dx];
o3 = [10.703 106.75+dx];
patch([o1(2) o3(2) o3(2) o1(2)],[o1(1)-dz o3(1)-dz o3(1)+dz o3(1)+dz],'k','LineWidth',0.5)
patch([o1(2) o2(2) o2(2) o1(2)],[o1(1)-dz o2(1)-dz o2(1)+dz o3(1)+dz],'w','LineWidth',0.5)
text(o1(2)-dz,o1(1)-4*dz,'0','FontSize',FS);
text(o2(2)-dz,o2(1)-4*dz,'5','FontSize',FS);
text(o3(2)-dz,o3(1)-4*dz,'10km','FontSize',FS);
set(gcf,'Color','white');

% Add panel id
annotation('textbox',[0.12 0.735 0.05 0.06],'String','(a)','FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','w','FontSize',FS)
text(o2(2),o2(1)+6*dz,'T_R = 100yr','FontSize',FS,'HorizontalAlignment','center','FontWeight','bold');

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file
dpi = '300';
pname = [dtop,'Fig01-Hazard'];
nfolder = [dtop,'Risk Assessment\Figures\',version,'\'];
mkdir([nfolder]);
export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

%% VULNERABILITY mapping
GFZ = shaperead([root,'zoftmax(3h100y_BC2_Res90).shp']);

for dd = 1:length(GFZ)
    x(dd) = mean(GFZ(dd).X,'omitnan');
    y(dd) = mean(GFZ(dd).Y,'omitnan');
    z(dd) = GFZ(dd).b_exp;
end

[xx yy] = meshgrid(min(x):0.00137329101562500:max(x),min(y):0.00134871365043843:max(y));
zz = griddata(x,y,z,xx,yy);
ind = inpolygon(xx,yy,C.X,C.Y);
zz(~ind) = nan;

% Plot point data as (filled) scatter
close all
figure; hold on; box on;
set(gca,'FontSize',FS);
pc = pcolor(xx,yy,zz); shading interp;  
load('acton.mat'); N = 9;
acton = downsample(acton,round(length(acton)/N)); acton = vertcat([acton(2:end,:)],[1 1 1]);
colormap(flip(acton)); cbs = colorbar; set(cbs,'Location','EastOutside');
cbs.Label.String = 'Relative Damage (%)'; cbs.FontSize = FS;
clim([0.0 0.25]); cbs.Ticks  = [0:0.05:0.5];

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add km scale
dz = 0.003; dx = 0.11;
o1 = [10.703,106.6586+dx];
o2 = [10.703 106.7043+dx];
o3 = [10.703 106.75+dx];
patch([o1(2) o3(2) o3(2) o1(2)],[o1(1)-dz o3(1)-dz o3(1)+dz o3(1)+dz],'k','LineWidth',0.5)
patch([o1(2) o2(2) o2(2) o1(2)],[o1(1)-dz o2(1)-dz o2(1)+dz o3(1)+dz],'w','LineWidth',0.5)
text(o1(2)-dz,o1(1)-4*dz,'0','FontSize',FS);
text(o2(2)-dz,o2(1)-4*dz,'5','FontSize',FS);
text(o3(2)-dz,o3(1)-4*dz,'10km','FontSize',FS);
set(gcf,'Color','white');

% Add panel id
annotation('textbox',[0.12 0.735 0.05 0.06],'String','(b)','FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','w','FontSize',FS)
text(o2(2),o2(1)+6*dz,'T_R = 100yr','FontSize',FS,'HorizontalAlignment','center','FontWeight','bold');

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file
dpi = '300';
pname = [dtop,'Fig01-Vulnerability'];
% mkdir([dtop,'Figures\RiskFactors\']);
export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

%% BUILDING EXPOSURE mapping
GFZ = shaperead([root,'zoftmax(3h100y_BC2_Res90).shp']);

for dd = 1:length(GFZ)
    x(dd) = mean(GFZ(dd).X,'omitnan');
    y(dd) = mean(GFZ(dd).Y,'omitnan');
    z(dd) = (GFZ(dd).abs_exp ./ GFZ(dd).b_exp) ./ GFZ(dd).area;
end

[xx yy] = meshgrid(min(x):0.00137329101562500:max(x),min(y):0.00134871365043843:max(y));
zz = griddata(x,y,z,xx,yy);
ind = inpolygon(xx,yy,C.X,C.Y);
zz(~ind) = nan;

% Plot point data as (filled) scatter
close all
figure; hold on; box on;
set(gca,'FontSize',FS);
% scatter(xx,yy,1,zz,'fill');
pcolor(xx,yy,zz); shading interp
load('bamako.mat'); N = 9;
bamako = downsample(bamako,round(length(bamako)/N)); bamako = vertcat([bamako(2:end,:)],[1 1 1]);
colormap(flip(bamako)); cbs = colorbar; set(cbs,'Location','EastOutside');
cbs.Label.String = 'Reconstruction Costs ($/m^2)'; cbs.FontSize = FS;
clim([0.0 50]); cbs.Ticks = [0:10:50];

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add km scale
dz = 0.003; dx = 0.11;
o1 = [10.703,106.6586+dx];
o2 = [10.703 106.7043+dx];
o3 = [10.703 106.75+dx];
patch([o1(2) o3(2) o3(2) o1(2)],[o1(1)-dz o3(1)-dz o3(1)+dz o3(1)+dz],'k','LineWidth',0.5)
patch([o1(2) o2(2) o2(2) o1(2)],[o1(1)-dz o2(1)-dz o2(1)+dz o3(1)+dz],'w','LineWidth',0.5)
text(o1(2)-dz,o1(1)-4*dz,'0','FontSize',FS);
text(o2(2)-dz,o2(1)-4*dz,'5','FontSize',FS);
text(o3(2)-dz,o3(1)-4*dz,'10km','FontSize',FS);
set(gcf,'Color','white');

% Add panel id
annotation('textbox',[0.12 0.735 0.05 0.06],'String','(c)','FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','w','FontSize',FS)

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file 
dpi = '300';
pname = [dtop,'Fig01-BuildingExposure'];
% mkdir([dtop,'Figures\RiskFactors\']);
export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

%% POPULATION EXPOSURE mapping
POP = shaperead([qgis,'HCMC_ward_population_ndvi_2019_4326.shp']);
load('bilbao.mat'); N = 9;
bilbao = downsample(bilbao,round(length(bilbao)/N));

% Open figure and project
figure; grid on;
set(gca,'FontSize',FS);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6777   10.9190],"MapLonLimit",[106.5357  106.9000])
maxD = 0.05; %EXAMPLE OF RIGID THRESHOLD
ind = find([POP.PopDensity] > maxD);
if ~isempty(ind)
    [POP(ind).PopDensity] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"PopDensity",[0 maxD],"FaceColor",bilbao,"EdgeColor",[0.75 0.75 0.75]});
geoshow(POP,"SymbolSpec",polyColors)
set(gca,'FontSize',FS);
colormap(bilbao); clim([0 maxD]);
cb = colorbar; cb.Label.String = 'Population Density (Pers./m^2)';
cb.FontSize = FS;

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add km scale
dz = 0.003; dx = 0.11;
o1 = [10.703,106.6586+dx];
o2 = [10.703 106.7043+dx];
o3 = [10.703 106.75+dx];
patch([o1(2) o3(2) o3(2) o1(2)],[o1(1)-dz o3(1)-dz o3(1)+dz o3(1)+dz],'k','LineWidth',0.5)
patch([o1(2) o2(2) o2(2) o1(2)],[o1(1)-dz o2(1)-dz o2(1)+dz o3(1)+dz],'w','LineWidth',0.5)
text(o1(2)-dz,o1(1)-4*dz,'0','FontSize',FS);
text(o2(2)-dz,o2(1)-4*dz,'5','FontSize',FS);
text(o3(2)-dz,o3(1)-4*dz,'10km','FontSize',FS);
set(gcf,'Color','white');

% Add panel id
annotation('textbox',[0.12 0.735 0.05 0.06],'String','(d)','FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','w','FontSize',FS)

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
% title({['Exposure: Asset Values (BC2 3h100y)'],''},'FontWeight','bold');
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file (could be copied anywhere after installing export_fig)
dpi = '300';
pname = [dtop,'Fig01-PopulationExposure'];
% mkdir([dtop,'Figures\RiskFactors\']);
export_fig([nfolder,pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

%% HOUSEHOLD EXPOSURE
POP = shaperead([qgis,'HCMC_population_2019_4326.shp']);
HH = [POP.Population] ./ [POP.Persons_hh];
HHm2 = [HH] ./ [POP.Area];
for i = 1:numel(POP)
    POP(i).HH = HH(i);
    POP(i).HHm2 = HHm2(i) * 1e6 / 1e3; % k Households per km2
end
% Fill district table W with aggregates
for d = 1:numel(D)
    Dists = {POP(:).TEN_HUYEN};
    if ismember(d,[1:4 17:19])
        ind1 = strcmp(Dists,[D(5).NAME_2(1:5) D(d).NAME_2]);
    else
        ind1 = strcmp(Dists,D(d).NAME_2);
    end
    ind = find(ind1==1);

    D(d).DistHH = sum([POP(ind).HH]);
    D(d).DistHHm2 = (D(d).DistHH ./ D(d).Area) * 1e6 / 1e3;
end
load('bilbao.mat'); N = 9;
bilbao = downsample(bilbao,round(length(bilbao)/N));

% Open figure and project
figure; grid on;
set(gca,'FontSize',FS);
axesm("MapProjection","eqaconic","MapParallels",[], ...
    "MapLatLimit",[10.6777   10.9190],"MapLonLimit",[106.5357  106.9000])
maxD = 25; %EXAMPLE OF RIGID THRESHOLD
ind = find([POP.HHm2] > maxD);
if ~isempty(ind)
    [POP(ind).HHm2] = deal(maxD);
end

polyColors = makesymbolspec("Polygon",{"HHm2",[0 maxD],"FaceColor",bilbao,"EdgeColor",[0.75 0.75 0.75]});
geoshow(POP,"SymbolSpec",polyColors)
set(gca,'FontSize',FS);
colormap(bilbao); clim([0 maxD]);
cb = colorbar; cb.Label.String = 'Household Density (10^3 HH/km^2)';
cb.FontSize = FS;

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add district/ward boundaries
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
end

% Add km scale
dz = 0.003; dx = 0.11;
o1 = [10.703,106.6586+dx];
o2 = [10.703 106.7043+dx];
o3 = [10.703 106.75+dx];
patch([o1(2) o3(2) o3(2) o1(2)],[o1(1)-dz o3(1)-dz o3(1)+dz o3(1)+dz],'k','LineWidth',0.5)
patch([o1(2) o2(2) o2(2) o1(2)],[o1(1)-dz o2(1)-dz o2(1)+dz o3(1)+dz],'w','LineWidth',0.5)
text(o1(2)-dz,o1(1)-4*dz,'0','FontSize',FS);
text(o2(2)-dz,o2(1)-4*dz,'5','FontSize',FS);
text(o3(2)-dz,o3(1)-4*dz,'10km','FontSize',FS);
set(gcf,'Color','white');

% Add panel id
annotation('textbox',[0.12 0.735 0.05 0.06],'String','(d)','FontWeight','bold',...
    'HorizontalAlignment','center','VerticalAlignment','middle','BackgroundColor','w','FontSize',FS)

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file (could be copied anywhere after installing export_fig)
dpi = '300';
pname = [dtop,'Fig01-HouseholdExposure'];
% mkdir([dtop,'Figures\RiskFactors\']);
export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);
