close all; clear all; clc;

% Fig. 1: HCMC location
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

%% TOPOGRAPHY and ADMINISTRATION
[Z R] = geotiffread([qgis,'LuFI-DEM_4326.tif']);
[X Y] =  geographicGrid(R); %[X Y] = utm2deg(X,Y,repmat('48N',[size(X)]));

ind = inpolygon(Y,X,C.X,C.Y);
Z(~ind) = nan;

%% Plot point data as surface
close all
figure; hold on; box on;
pcolor(Y,X,Z);
shading interp; daspect([1 1 1]);
load('broc.mat'); N = 22;
broc = downsample(broc,round(length(broc)/N));
colormap([broc(9:end-4,:)]); cbs = colorbar; set(cbs,'Location','EastOutside');
cbs.Label.String = 'Surface Elevation (mASL)'; cbs.FontSize = 8;
clim([-10 15]); cbs.Ticks  = [-10:5:50];

% Add district/ward boundaries
load('Positions.mat')
patch(C.X,C.Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',2*LW)
for d = 1:length(D)
    patch(D(d).X,D(d).Y,'w','FaceAlpha',0,'EdgeColor','k','LineWidth',LW)
    plot(Positions(1,d),Positions(2,d),'o','MarkerFaceColor','w',...
        'MarkerEdgeColor','k','Marker','o','MarkerSize',8,'AlignVertexCenters','on')
    t(d) = text(Positions(1,d),Positions(2,d),num2str(d),'FontSize',5,...
        'HorizontalAlignment','center','VerticalAlignment','middle');
end

% Add panel with district names
bx = patch([106.78 106.91 106.91 106.78],[10.67 10.67 10.8 10.8],'w','FaceAlpha',0.7,'EdgeColor','k');
for d=1:19
    if d<=10
        e1(d) = plot(106.79,10.805-0.012*d,'o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',8);
        e2(d) = text(106.79,10.805-0.012*d,num2str(d),'FontSize',5,...
            'HorizontalAlignment','center','VerticalAlignment','middle');
        e3(d) = text(106.80,10.805-0.012*d,D(d).NAME_2,'FontSize',5,...
            'HorizontalAlignment','left','VerticalAlignment','middle');
    else
        e1(d) = plot(106.85,10.805-0.012*(d-10),'o','MarkerFaceColor','w','MarkerEdgeColor','k','MarkerSize',8);
        e2(d) = text(106.85,10.805-0.012*(d-10),num2str(d),'FontSize',5,...
            'HorizontalAlignment','center','VerticalAlignment','middle');
        e3(d) = text(106.86,10.805-0.012*(d-10),D(d).NAME_2,'FontSize',5,...
            'HorizontalAlignment','left','VerticalAlignment','middle');
    end
end
set(gca,'Layer','top')
set(gcf,'Color','white');

% Beautify plot sheet
axis padded
axis([106.5357  106.9000   10.6777   10.9190])
xticks(106.5:0.1:106.9); xtickformat('%.2f\x00B0 E');
yticks(10.7:0.1:10.9); ytickformat('%.2f\x00B0 N'); ytickangle(90)
% title({['Hazard: Water Depth (BC2 3h100y)'],''},'FontWeight','bold');
daspect([1 1 1]); grid on;
set(gcf,'Color','white');

% Print to file
dpi = '300';
pname = [dtop,'Fig01-Topography'];
export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

