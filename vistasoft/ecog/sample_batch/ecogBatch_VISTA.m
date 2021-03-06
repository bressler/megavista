
function ecogBatch_VISTA(subjnum,block,flags,basepath)
% ecogBatch_VISTA(subjnum,block,flags,basepath)
% Usage:
% ecogBatch('02','ST03_bl76','pfcdes');
% 
% The experiment name is VISTA
%
% This batch function will call makeparSubj02VISTA.m to generate a
% parameter file for the desired block, parSubj02VISTA.mat, and store
% it in the RawData/block directory
%
% flags:
% p: Create parfile, otherwise load existing parfile.
% f: Filter (ecogNoiseFiltData)
% a: Artifact replacement (ecogArtReplace)
% c: Common average reference (ecogCommonAvgRef)
% d: Calculate amplitude & phase (ecogDataDecompose)
% t: Set timestamps (ecogStampfunc)
% e: Make ERPs (ecogERP)
% s: Make ERSPs (ecogERSP)
%
% basepath is an optional argument
%
% j.chen 07/12/10

%% Paths
if ~exist('basepath','var')
    basepath = ['/Users/kanile/biac3-wagner7/ecog/subj' subjnum '/ecog/VISTA'];
end
addpath(basepath);
parfile = fullfile(basepath,'RawData',block,['parSubj' subjnum 'VISTA.mat']); % generated by makeparSubj02miniKM.m
if exist(parfile,'file')
    load(parfile)
else
    funcname = ['makeparSubj' subjnum 'VISTA'];
    cmd = ['par = ' funcname '(block,basepath,parfile)'];
    eval(cmd);
end
par.basepath = basepath;
% Update path info based on par.basepath
par = ecogPathUpdate(par);

%% Create parameters
if ismember('p',flags)
    % Create a new parfile
    % par = makeparSubj<subj#><exptname>(block,basepath,parfile);
    funcname = ['makeparSubj' subjnum 'VISTA'];
    cmd = ['par = ' funcname '(block,basepath,parfile)'];
    eval(cmd);
end
par.basepath = basepath;
% Update path info based on par.basepath
par = ecogPathUpdate(par);

% Remove missing channels from electrode list
elecs = [1:par.nchan];
if isfield(par,'missingchan')
    elecs=elecs(~ismember(elecs,par.missingchan));
end

% The reference, epileptic and "bad" channels should never be included in
% the CAR. They are removed within ecogCommonAvgRef. However, we do want to
% subtract the CAR from everything BUT the reference, so they are still included
% in elecs when we pass it to ecogNoiseFiltData and ecogCommonAvgRef.

%% Filter 60 Hz line noise
if ismember('f',flags')
    ecogNoiseFiltData(par,elecs);
end

%% Artifact detection/replacement
if ismember('a',flags)
    % outMat = ecogArtReplace(par,elecs,doreplace,threshstd,rejectwins,showme)
    outMat = ecogArtReplace(par,elecs,1,5,0,0);
end

%% re-referencing data to the common average reference CAR
if ismember('c',flags)
    ecogCommonAvgRef(par,'artRep',elecs) % 'orig','noiseFilt','artRep'
end

%% Remove bad (but not epileptic) channels from remaining analyses
elecs=elecs(~ismember(elecs,par.badchan));

%% Calculate power in defined frequency band
if ismember('b',flags)
    ecogBBcalc(par,elecs,minfreq,maxfreq);
end

%% Decompose signal into Amplitude and Phase for different frequencies
if ismember('d',flags)
    overwrite = 1;
    ecogDataDecompose(par,elecs,overwrite);
end

%% Assign timestamps
stampspath = fullfile(par.BehavData,['pdioevents_' par.block '.mat']);
if ismember('t',flags)
    [truestamps,conds,firstEvent] = ecogStampfunc(par.RawData,par.BehavData,par.pdiochan,...
        par.ieegrate,par.pdiorate,par.eventfile);
    save(stampspath,'truestamps','firstEvent','conds');
end

%% Set conds
if ismember('e',flags) || ismember('s',flags) || ismember('z',flags) || ismember('k',flags)
    load(stampspath);
    
    % Remove stamps that overlap periods identified as outliers by ArtReplace
    % Checks only in par.rejelecs for outliers
    otl_bef_win = 0.2;
    otl_aft_win = 1.5;
    % bad_count: how many events rejected
    % bad_conds: list of conditions of events rejected
    [truestamps conds bad_count bad_conds] = ...
        ecogCleanStamps(par,truestamps,conds,otl_bef_win,otl_aft_win);
    
    % Conditions
    bef_win = 0.2; % AIN 1p7
    aft_win = 1.5;
    condnames = {...
        'all','istudy','itest','astudy','atest',...
        'i01','i02','i03','a01','a02','a03',...
        'tihits','ticorj','tahits','tacorj'};
    codes.all = [1:8 11 13 15:18 21 23 25:28 31 33 35:38];
    codes.istudy = [11 13 21 23 31 33];
    codes.itest = [1:4];
    codes.astudy = [15:18 25:28 35:38];
    codes.atest = [5:8];
    codes.i01 = [11 13];
    codes.i02 = [21 23];
    codes.i03 = [31 33];
    codes.a01 = [15:18];
    codes.a02 = [25:28];
    codes.a03 = [35:38];
    codes.tihits = [1];
    codes.ticorj = [2];
    codes.tahits = [5];
    codes.tacorj = [6];
    condstamps = []; MXnumEvents = [];
    for n = 1:length(condnames)
        temp = [];
        for q = 1:length(codes.(condnames{n}))
            mycond = codes.(condnames{n})(q);
            temp = [temp; truestamps(conds==mycond)];
        end
        MXnumEvents(n) = length(temp);
        condstamps{n} = sort(temp);
    end

    % These time periods will be used to calculate Stdevs for this block:
    % only the windows that actually go into trials
    temp = [];
    for n = 1:length(codes.all)
        mycond = codes.all(n);
        temp = [temp; truestamps(conds==mycond)];
    end
    keptstamps = temp;
        
    clear startstamps; clear endstamps;
    startstamps = keptstamps - otl_bef_win;
    endstamps = keptstamps + otl_aft_win;
    
    if 0
        figure;
        for r = 1:length(par.rejelecs)
            fname = sprintf('%s/CARiEEG%s_%.2d.mat',par.CARData,par.block,par.rejelecs(r));
            car = load(fname);
            fname = sprintf('%s/aiEEG%s_%.2d.mat',par.ArtData,par.block,par.rejelecs(r));
            art = load(fname);
            subplot(length(par.rejelecs),1,r);
            plot(car.wave,'b-'); hold on
            plot(find(art.outliers),art.wave(find(art.outliers)),'r.');
            for i = 1:length(startstamps)
                plot([startstamps(i)*par.ieegrate endstamps(i)*par.ieegrate],[0 0],'c-');
            end
            title([par.subjname ' ' par.block ': Elec ' num2str(par.rejelecs(r))]);
        end
    end
end

%% Generating ERP
if ismember('e',flags)
    poststimbase = 0;
    ecogERP(par,bef_win,aft_win,condstamps,condnames,elecs,poststimbase);
end

%% Generating ERSP
if ismember('s',flags)
    ecogERSP(par,bef_win,aft_win,condstamps,condnames,elecs);
end

%% Generating Stdev and ZERP
if ismember('z',flags)
    poststimbase = 0;
    stdev = ecogStdev(par,startstamps,endstamps,elecs);
    ecogZERP(par,stdev,bef_win,aft_win,condstamps,condnames,elecs,poststimbase);
end








