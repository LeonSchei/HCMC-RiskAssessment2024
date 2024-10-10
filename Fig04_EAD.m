close all; clear all; clc;
warning off;

%% Fig 4. Expected Annual Damage (EAD)
% Scheiber et al. 2024

% Define folders and files
version = 'September2023-D';
dtop = 'C:\Users\scheiber\Desktop\';
root = [dtop,'Risk Assessment\GFZ\',version,'\'];
qgis = [dtop,'Risk Assessment\QGIS\'];
addpath(genpath('C:\Users\scheiber\Documents\MATLAB\'))

allfiles = dir([root,'*.shp']);

% Define filter criteria for adaptation
% USE EMPTY f1 FOR EAD
% OR RETURN PERIOD FOR ABS/REL DAMAGE
f1 = '';  % Any return period (e.g. 3h100y)
f2 = 'BC2';     % BC2  = Ring dike
f3 = '15hR';    % 15hR = Rainwater detention
f4 = 'PPM';     % PPM  = private precautionary measures

%% Choose scenario
run = 'casesPPM50\';
% % Base Case 2
% ind = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & ~contains({allfiles(:).name},f3) & ~contains({allfiles(:).name},f4);
% ind2 = ind;
% % Rainwater Detention only
% ind = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & contains({allfiles(:).name},f3) & ~contains({allfiles(:).name},f4);
% ind2 = ind;
% Private Precaution only
% PPM = 1;
% ind = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & ~contains({allfiles(:).name},f3) & contains({allfiles(:).name},f4);
% ind2 = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & ~contains({allfiles(:).name},f3) & ~contains({allfiles(:).name},f4);
% % Combination of PPM and 15hR
PPM = 1;
ind = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & contains({allfiles(:).name},f3) & contains({allfiles(:).name},f4);
ind2 = contains({allfiles(:).name},f1) & contains({allfiles(:).name},f2) & contains({allfiles(:).name},f3) & ~contains({allfiles(:).name},f4);

% See what goes out
clc; disp([num2str(sum(ind)),' file(s) found: '])
format compact; n=1;
files  = allfiles(ind); allfiles(ind).name
files2  = allfiles(ind2); allfiles(ind2).name

% Sort by new field return period (RP)
for i = 1:length(files)
    files(i).RP = str2num(files(i).name(strfind(files(i).name,'3h')+2:strfind(files(i).name,'y')-1));
    files2(i).RP = str2num(files2(i).name(strfind(files2(i).name,'3h')+2:strfind(files2(i).name,'y')-1));
end
files = table2struct(sortrows(struct2table(files),'RP'));
files2 = table2struct(sortrows(struct2table(files2),'RP'));

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
    %     scen = split(casename); scen = scen{2,1};
    cname = ['D2_',f1,casename(6:end),'_',version];
end

% Loop over all return periods and calculate EAD
if exist([run,f1,cname,'.mat']) ~= 2
    for f = 1:numel(files)

        % Open ward and results file
        W = shaperead([qgis,'HCMC-districts2.shp']); 
        W2 = shaperead([qgis,'HCMC_ward_population_ndvi_2019_4326.shp']);
        Di1 = shaperead([root,files(f).name]);
        Di2 = shaperead([root,files2(f).name]);

        % Average data and delete rows with 0 data
        Di1([Di1.abs_exp]==0)=[];
        Di2([Di2.abs_exp]==0)=[];
        fields = fieldnames(Di1);
        for d = 1:numel(Di1)
            for ff = 1:numel(fields)
                if ff<7
                    Di(d,:).(fields{ff}) = Di1(d).(fields{ff});
                else
                    Di(d,:).(fields{ff}) = mean([Di1(d).(fields{ff}) Di2(d).(fields{ff})]);
                end
            end
        end
        clear vars Di1 Di2 fields

        for w = 1:length(W2)

            % Replace crazy district names and aggregate data
            ind = dsearchn([W(:).Area]',W2(w).DistArea);
            W2(w).District = W(ind).NAME_2;

            clc
            n = n+1;
            N = length(W2)*length(files);
            disp(['Ward ',num2str(n),'/',num2str(N-1),' processed...'])

            % Add ID, district and name of each ward
            D2(w).District = string(W2(w).District);
            D2(w).Population = W2(w).Population;
            if D2(w).Population == 0
                D2(w).Population = 15435;   % Filled nan with wiki information
            end
            D2(w).X = W2(w).X; D2(w).Y = W2(w).Y;
            D2(w).Area = W2(w).area;
            D2(w).Geometry = 'Polygon';

            % Add zeros as absolute and relative damages for each return period
            D2(w).RP(f) = files(f).RP;
            D2(w).AbsD(f) = 0;
            D2(w).RelD(f) = 0;

            % Calculate sum / mean for all pixels in district
            for ii = 1:length(Di)
                xx(ii) = mean(Di(ii).X,'omitnan');
                yy(ii) = mean(Di(ii).Y,'omitnan');
            end
            ind = inpolygon(xx,yy,D2(w).X,D2(w).Y);
            D2(w).AbsD(f) = sum([Di(ind).abs_exp]);
            D2(w).AbsL(f) = sum([Di(ind).abs_low]);
            D2(w).AbsH(f) = sum([Di(ind).abs_high]);
            D2(w).AbsDn(f) = D2(w).AbsD(f) / D2(w).Area; % Normalization over area
            D2(w).AbsLn(f) = D2(w).AbsL(f) / D2(w).Area; % Normalization over area
            D2(w).AbsHn(f) = D2(w).AbsH(f) / D2(w).Area; % Normalization over area
            D2(w).AbsDp(f) = D2(w).AbsD(f) / D2(w).Population; % Normalization over population
            D2(w).AbsLp(f) = D2(w).AbsL(f) / D2(w).Population; % Normalization over population
            D2(w).AbsHp(f) = D2(w).AbsH(f) / D2(w).Population; % Normalization over population
            D2(w).RelD(f) = mean([Di(ind).b_exp]);
            D2(w).RelL(f) = mean([Di(ind).b_low]);
            D2(w).RelH(f) = mean([Di(ind).b_high]);
            clear ind xx yy
        end
    end

    for w = 1:numel(D2)
        % Find and aggregate EAD by district
        Dists = {W2(:).District};
        ind = strcmp(Dists,W2(w).District);
        D2(w).DistPop = sum([D2(ind).Population]);
        D2(w).DistArea = sum([D2(ind).Area]);
        D2(w).DistRelD = nanmean([D2(ind).RelD]);
        D2(w).DistRelL = nanmean([D2(ind).RelL]);
        D2(w).DistRelH = nanmean([D2(ind).RelH]);
        D2(w).DistAbsD = sum([D2(ind).AbsD]);
        D2(w).DistAbsL = sum([D2(ind).AbsL]);
        D2(w).DistAbsH = sum([D2(ind).AbsH]);
        D2(w).DistAbsDn = sum([D2(ind).AbsD]) / D2(w).DistArea;
        D2(w).DistAbsLn = sum([D2(ind).AbsL]) / D2(w).DistArea;
        D2(w).DistAbsHn = sum([D2(ind).AbsH]) / D2(w).DistArea;
        D2(w).DistAbsDp = sum([D2(ind).AbsD]) / D2(w).DistPop;
        D2(w).DistAbsLp = sum([D2(ind).AbsL]) / D2(w).DistPop;
        D2(w).DistAbsHp = sum([D2(ind).AbsH]) / D2(w).DistPop;
    end

    % Fill district table W with aggregates
    for w = 1:numel(W)
        ind = strcmp(Dists,W(w).NAME_2);
        ind2 = find(ind==1);
        W(w).District = D2(ind2(1)).District;
        W(w).RelD = D2(ind2(1)).DistRelD;
        W(w).RelL = D2(ind2(1)).DistRelL;
        W(w).RelH = D2(ind2(1)).DistRelH;
        W(w).AbsD = D2(ind2(1)).DistAbsD;
        W(w).AbsL = D2(ind2(1)).DistAbsL;
        W(w).AbsH = D2(ind2(1)).DistAbsH;
        W(w).AbsDn = D2(ind2(1)).DistAbsDn;
        W(w).AbsLn = D2(ind2(1)).DistAbsLn;
        W(w).AbsHn = D2(ind2(1)).DistAbsHn;
        W(w).AbsDp = D2(ind2(1)).DistAbsDp;
        W(w).AbsLp = D2(ind2(1)).DistAbsLp;
        W(w).AbsHp = D2(ind2(1)).DistAbsHp;
        W(w).Pop = D2(ind2(1)).DistPop;
    end

    % Save scenario to cases folder
    save([run,f1,cname],'D2','W2','W')

else
    load([run,f1,cname])
end

%% Calculate Expected annual damage (EAD) and Expected total damage (area below curve)
if isempty(f1)

    scen = casename(6:end);

    for d = 1:length(D2)
        D2(d).EAD = trapz(flip(1./D2(d).RP),flip(D2(d).AbsD));
        D2(d).EADL = trapz(flip(1./D2(d).RP),flip(D2(d).AbsL));
        D2(d).EADH = trapz(flip(1./D2(d).RP),flip(D2(d).AbsH));
    end

    for w = 1:numel(D2)
        % Find and aggregate EAD by district
        Dists = {W2(:).District};
        ind = strcmp(Dists,W2(w).District);
        D2(w).DistEAD = sum([D2(ind).EAD]);
        D2(w).DistEADH = sum([D2(ind).EADH]);
        D2(w).DistEADL = sum([D2(ind).EADL]);
        D2(w).DistPop = sum([D2(ind).Population]);
    end

    % Fill district table W with aggregates
    for w = 1:numel(W)
        ind = strcmp(Dists,W(w).NAME_2);
        ind2 = find(ind==1);
        W(w).District = D2(ind2(1)).District;
        W(w).DistEAD = D2(ind2(1)).DistEAD;
        W(w).DistEADH = D2(ind2(1)).DistEADH;
        W(w).DistEADL = D2(ind2(1)).DistEADL;
        W(w).DistPop = D2(ind2(1)).DistPop;
    end

    if contains(casename,f2) & ~contains(casename,f3) & ~contains(casename,f4)
        save([run,'BaseCase2_',f1,version,'.mat'],'D2','W2','W')
    end
    save([run,f1,cname],'D2','W2','W')

    %% Plot examplary risk curve
    close all;
    figure; hold on; box on;
    AbsD = plot(mean(vertcat(D2(:).RP)),sum(vertcat(D2(:).AbsD)),'k','LineWidth',1.5);
    AbsL = plot(mean(vertcat(D2(:).RP)),sum(vertcat(D2(:).AbsL)),'k:','LineWidth',0.5);
    AbsH = plot(mean(vertcat(D2(:).RP)),sum(vertcat(D2(:).AbsH)),'k:','LineWidth',0.5);
    IQR = patch([mean(vertcat(D2(:).RP)) fliplr(mean(vertcat(D2(:).RP)))],...
        [sum(vertcat(D2(:).AbsH)) fliplr(sum(vertcat(D2(:).AbsL)))], ...
        'b','FaceAlpha',0.2,'LineStyle','none');
    EAD = yline(sum([D2(:).EAD]),'--');
    text(0.7,0.05,['EAD = ',num2str(round(sum([D2(:).EAD] / 1e6),1)),' Mio $'],'units','normalized');
    lgd = legend([AbsD,EAD],'Aggregated abs. damage ($)','Expected annual damage ($)','Location','northwest');
    xlabel('Return period (years)'); xticks([D2(1).RP]);
    xlim([1 100]); ylim([0 3e9])
    ylabel('Expected damage (Mio $)');
    title({['HCMC flood risk (', scen,')'],''},'FontWeight','normal');
    set(gcf,'Color','white');

    % Print to file (could be copied anywhere after installing export_fig)
    dpi = '300';
    pname = [dtop,'Fig01-HCMC-meanEAD_',scen];
    %     export_fig([nfolder,'RiskCuve_',scen,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

    %% Plot choropleth for EAD
    % Load and define colormap
    N = 9; FA = 0.5; FS = 7;
    load('lajolla.mat');
    lajolla = downsample(lajolla,round(length(lajolla)/N)); lajolla = lajolla(2:end-1,:);

    D3 = D2;

    % Open figure and project
    figure; grid on;
    s1 = subplot(2,1,1);
    axesm("MapProjection","eqaconic","MapParallels",[], ...
        "MapLatLimit",[10.6500   10.9500],"MapLonLimit",[106.5500  106.9000])

    for d = 1:numel(D2)
        D2(d).EAD = D2(d).EAD / 1e6;
        D2(d).EADH = D2(d).EADH / 1e6;
        D2(d).EADHL = D2(d).EADL / 1e6;
        D2(d).DistEAD = D2(d).DistEAD / 1e6;
        D2(d).DistEADH = D2(d).DistEADH / 1e6;
        D2(d).DistEADL = D2(d).DistEADL / 1e6;
    end

    [~, orderEAD] = sort([W.DistEAD], 'descend');
    maxD = 40; %max([D2.EAD]); %EXAMPLE OF RIGID THRESHOLD
    ind = find([D2.EAD] > maxD);
    if ~isempty(ind)
        [D2(ind).EAD] = deal(maxD);
    end

    polyColors = makesymbolspec("Polygon",{"EAD",[0 maxD],"FaceColor",lajolla,"EdgeColor",[0.5 0.5 0.5]});
    geoshow(D2,"SymbolSpec",polyColors)
    colormap(lajolla); clim([0 maxD]);
    cb = colorbar; % cb.Label.String = 'Expected annual damage (Mio $)';

    % Beautify plot
    DIKE = shaperead([root(1:42),'QGIS\RingDike4326.shp']);
    DIKE = patch(DIKE.X,DIKE.Y,[0.25 0.25 0.25],'FaceAlpha',0,'LineWidth',2,'EdgeColor',[0.25 0.25 0.25]);
    axis padded
    xticks(106.5:0.1:106.9);
    xticklabels('')
    yticks(10.7:0.1:10.9);
    yticklabels('')
    title({['EAD in Million dollars (10^6 $)'],''},'FontWeight','normal')
    text(0.82,0.13,{'EAD_{tot}',[sprintf('%0.1f',sum([W(:).DistEAD])/1e6),' \times10^6 $']}, ...
        'units','normalized','FontSize',FS,'HorizontalAlignment','center');

    % Add districts
    for d = 1:numel(W)
        patch((W(d).X),(W(d).Y),'w','FaceAlpha',0,'EdgeColor',[0.5 0.5 0.5],'LineWidth',1)
    end
    set(gcf,'Color','white');

    % Add ranking
    for i = 1:3
        sq(i) = plot(mean((W(orderEAD(i)).X),'omitnan'), mean((W(orderEAD(i)).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
        sq(i+3) = plot(mean((W(orderEAD(end-3+i)).X),'omitnan'), mean((W(orderEAD((end-3+i))).Y),'omitnan'),'MarkerFaceColor','w','MarkerEdgeColor','k','Marker','square','MarkerSize',FS+3,'LineWidth',0.5)
        text(i, -0.5*maxD , W(orderEAD(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
        text(4+i, -0.5*maxD , W(orderEAD(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
        t(i) = text(mean((W(orderEAD(i)).X),'omitnan'), mean((W(orderEAD(i)).Y),'omitnan'), num2str(i),'color','black','FontWeight','normal','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
        t(i+3) = text(mean((W(orderEAD(end-3+i)).X),'omitnan'), mean((W(orderEAD((end-3+i))).Y),'omitnan'), num2str(16+i) ,'color',[0.25 0.25 0.25],'FontWeight','bold','FontSize',FS,'HorizontalAlignment','center','VerticalAlignment','middle');
        p(i) = patch((W(orderEAD(i)).X),(W(orderEAD(i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
        p(i+3) = patch((W(orderEAD(end-3+i)).X),(W(orderEAD(end-3+i)).Y),'w','FaceAlpha',0,'LineWidth',1,'EdgeColor','k');
    end

    uistack(sq,'top');
    uistack(t,'top');

    s2 = subplot(2,1,2);
    %     [~, orderEAD] = sort([W.DistEAD], 'descend');
    maxD = 400; % max([W(:).DistEAD])

    bar(1:3,[W(orderEAD(1:3)).DistEAD] ./ 1e6,'facecolor',[214/256 103/256 78/256]); hold on;
    bar(1:3,[W(orderEAD(1:3)).DistEAD] ./ 1e6,'facecolor',[214/256 103/256 78/256]); hold on;
    bar(5:7,[W(orderEAD(end-2:end)).DistEAD] ./1e6,'facecolor',[214/256 103/256 78/256]); hold on;
    er = errorbar(1:3,[W(orderEAD(1:3)).DistEAD] ./ 1e6,[[W(orderEAD(1:3)).DistEAD]-[W(orderEAD(1:3)).DistEADL]] ./ 1e6,[[W(orderEAD(1:3)).DistEAD]-[W(orderEAD(1:3)).DistEADH]] ./ 1e6,'Color',[0.5 0.5 0.5],'LineStyle','none');
    er = errorbar(5:7,[W(orderEAD(end-2:end)).DistEAD] ./ 1e6,[[W(orderEAD(end-2:end)).DistEAD]-[W(orderEAD(end-2:end)).DistEADL]] ./ 1e6,[[W(orderEAD(end-2:end)).DistEAD]-[W(orderEAD(end-2:end)).DistEADH]] ./ 1e6,'Color',[0.5 0.5 0.5],'LineStyle','none');
    set(er,'Color',[0 0 0],'LineStyle','none');
    box off
    title('')
    set(gcf,'Color','white');
    set(s2,'YColor','w')
    xlim([0 8]); xticks([]); ylim([0 1.5*maxD]);
    set(s2,'position',[0.269047619047619,0.35,0.4045,0.2])
    set(s2,'YAxisLocation','right')

    oy = 1.2;
    text(1:3, ones(1,3)*oy*maxD, {'1','2','3'} ,'color','black','FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
    text(5:7, ones(1,3)*oy*maxD, {'17','18','19'} ,'color','black','FontWeight','normal','HorizontalAlignment','center','VerticalAlignment','middle','FontSize',FS);
    plot(1:3, ones(1,3)*oy*maxD,'k','MarkerSize',FS+3,'Marker','square','LineWidth',0.5,'LineStyle','none')
    plot(5:7, ones(1,3)*oy*maxD,'k','MarkerSize',FS+3,'Marker','square','LineWidth',0.5,'LineStyle','none')
    for i = 1:3
        text(i, [W(orderEAD(i)).DistEAD]/1e6,sprintf('%0.1f',W(orderEAD(i)).DistEAD/1e6),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',FS);
        text(4+i, [W(orderEAD(end-3+i)).DistEAD]/1e6,sprintf('%0.1f',W(orderEAD(end-3+i)).DistEAD/1e6),'color',[0 0 0],'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',FS);
        text(i, -0.2*maxD , W(orderEAD(i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
        text(4+i, -0.2*maxD , W(orderEAD(end-3+i)).District,'color',[0 0 0],'rotation',45,'HorizontalAlignment','right','VerticalAlignment','top','FontSize',FS);
    end

    % Print to file
    dpi = '300';
    fname = files(1).name(14:end);
    pname = [dtop,'Fig01-HCMC-EAD-Distribution_',scen];
    export_fig([pname,'_',datestr(now,'yyyy-mm-dd'),'.png'],'-painters',['-r',dpi]);

    % Write shape file
    fields = fieldnames(D2);
    for ff = 7:19
        D2 = rmfield(D2,fields(ff));
    end

    shapefolder = 'C:\Users\scheiber\Desktop\Scheiber et al. 2024\EADs\';
    shapename = [shapefolder,'EAD_',casename(6:end),'.shp'];
    shapewrite(D2,shapename)

    D2 = D3;
end
