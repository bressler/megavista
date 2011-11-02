function vw = findTalairachVolume(vw, varargin)% Create an ROI in the view from a set of talairach coords %%  vw = findTalairachVolume(vw)%% SEE ALSO:%   Anatomy code tree: computeTalairach, volToTalairach, talairachToVol%% HISTORY:%   2002.07.17 RFD (bob@white.stanford.edu) Added comments and minor code cleaning.curDir = pwd;tc = [];snc = [];radius = 5;roi_name = '';path = pwd;for i = 1:2:length(varargin)    switch (lower(varargin{i}))        case {'talairach' 'tal'}            tc = varargin{i + 1};        case {'mni'}            snc = varargin{i + 1};        case {'radius'}            radius = varargin{i + 1};        case {'name'}            roi_name = varargin{i + 1};        case {'path'}            path = varargin{i + 1};        case {'nomsg'}            nomsg = varargin{i + 1};        case {'growmethod'}  % disk or sphere            growmethod = varargin{i + 1};        otherwise            fprintf(1, 'Unrecognized option: ''%s''', varargin{i});    endendif (notDefined('vw'))    cd(path);    vw = initHiddenGray();    vw = loadAnat(vw);endif notDefined('growmethod')    growmethod = 'sphere';endif notDefined('nomsg')    nomsg = 0;endglobal mrSESSION;[talairach, spatialNorm] = loadTalairachXform(mrSESSION.subject, [], 1);global vANATOMYPATH;[p,f,e] = fileparts(vANATOMYPATH);% if(strcmp(e,'.dat'))%     fileType = 'dat';% else%     fileType = 'nifti';% endif (isempty(talairach) && isempty(spatialNorm))    return;endif (isempty(tc) && isempty(snc))    resp = inputdlg({...        'Enter Talairach coords (eg. [0,0,0]):', ...        'OR MNI coords (eg. [0,0,0]):', ...         'Radius (mm)', ...        'Name (option)'}, ...        'Find coords', 1, ...        {'', '', num2str(radius), roi_name});    tc = str2num(resp{1});    snc = str2num(resp{2});    radius = str2num(resp{3});    roi_name = resp{4};endif(isempty(spatialNorm) && ~isempty(snc))    error('No spatial norm exists! Try mrAnatComputeVanatSpatialNorm.');endinputCoords = snc;name = 'MNI';if (~isempty(tc))    snc = tal2mni(tc);    inputCoords = tc;    name = 'Talairach';endif (~isempty(snc))    if(~all(size(snc)==[1,3]))        error([mfilename,': Requires 3 coordinates.']);    end    sz = size(vw.anat);    coords = round(mrAnatXformCoords(spatialNorm.sn, snc));    c = [sz(3)-coords(:,3) sz(2)-coords(:,2) coords(:,1)];        if (isempty(tc)), tc = mni2tal(snc); endendif ~nomsg    msg = {'Coords:';        sprintf('Talairach (%0.1f, %0.1f, %0.1f)', tc); ...        sprintf('MNI (%0.1f, %0.1f, %0.1f)', snc); ...        sprintf('Volume (%0.1f, %0.1f, %0.1f) (Ax, Cor, Sag)', c)};    msgbox(msg,name);endname = sprintf('%s = (%0.1f, %0.1f, %0.1f), Radius = %0.1fmm', name, inputCoords, radius);if ~isempty(roi_name)    name = sprintf('%s (%s)', roi_name, name);endif strcmp(growmethod,'disk') || strcmp(growmethod,'disc')    [ignoreMe, roi] = makeROIdiskGray(vw, radius, name, [], [], c);else  % default to sphere    [ignoreMe, roi] = makeROIsphere(vw, radius, c, name);end% We try to be compatible with any vw. All analyses are performed on% gray vw ROIs, so the code here simply translates the current vw's% ROIs to the gray vw, and grabs a gray vw if one doesn't already exist.switch(vw.viewType)    case {'Inplane'}        error([mfilename,' doesn''t work for ',vw.viewType,'.']);    case 'Flat'        disp('Tranforming coordinates from volume to flat...');        roi.viewType = 'Volume';        gray = getSelectedGray;        if isempty(gray)            gray = initHiddenGray;        end        roi = vol2flatROI(roi, gray, vw);    case {'Volume','Gray'}        % this one requires no special preprocessing        roi.viewType = vw.viewType;    otherwise        error([vw.viewType,' is unknown!']);endvw = addROI(vw,roi);cd(curDir);return;