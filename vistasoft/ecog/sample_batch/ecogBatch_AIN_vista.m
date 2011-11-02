
function ecogBatch(subjnum,block,flags,basepath)
%
% Usage:
% ecogBatch('02','ST03_bl76','pfcdes');
% 
% This batch function will call makeparSubj02AIN.m to generate a
% parameter file for the desired block, parSubj02AIN.mat, and store
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
    basepath = ['/Users/kanile/biac3-wagner7/ecog/subj' subjnum '/ecog/AIN'];
end
addpath(basepath);
parfile = fullfile(basepath,'RawData',block,['parSubj' subjnum 'AIN.mat']); % generated by makeparSubj02miniKM.m
if exist(parfile,'file')
    load(parfile)
else
    funcname = ['makeparSubj' subjnum 'AIN'];
    cmd = ['par = ' funcname '(block,basepath,parfile)'];
    eval(cmd);
end
par.basepath = basepath;
% Update path info based on par.basepath
par = ecogPathUpdate(par);

%% Create parameters
if ismember('p',flags)
    % Create a new parfile
    % par = makeparSubj07AIN(block,basepath,parfile);
    funcname = ['makeparSubj' subjnum 'AIN'];
    cmd = ['par = ' funcname '(block,basepath,parfile)'];
    eval(cmd);
end

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
    % outMat = ecogArtReplace(par,elecs,doreplace,threshstd,rejectwins)
    outMat = ecogArtReplace(par,elecs,1,5,0,0);
end

%% re-referencing data to the common average reference CAR
if ismember('c',flags)
    ecogCommonAvgRef(par,'artRep',elecs) % 'orig','noiseFilt','artRep'
end

%% Remove bad and epileptic channels from remaining analyses
elecs=elecs(~ismember(elecs,par.badchan));
elecs=elecs(~ismember(elecs,par.epichan));

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
if ismember('e',flags) || ismember('s',flags)
    load(stampspath);
    bef_win = 0.2;
    aft_win = 1.5;
    % condstoprocess and condnames must be index-aligned and the same length!
    condstoprocess = [1 2 5 6];
    condnames = {'t-ihits','t-icorj','t-ahits','t-acorj'};
    condstamps = []; MXnumEvents = [];
    for n = 1:length(condstoprocess);
        mycond = condstoprocess(n);
        condstamps{n} = truestamps(find(conds==mycond));
        MXnumEvents(n) = length(condstamps{n});
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

% % Surrogate data for ERSP
% surr_iter = 1000; % should be bigger than 2 iterations
% ecogSurrogateERSP(par,bef_win,aft_win,condnames,MXnumEvents,surr_iter,elecs);
%
% % Normalizing ERSP with respect to surrogate data
% for n = 1:length(condstoprocess);
%     mycond = condnames{n};
%     ecogNormERSP(par,bef_win,aft_win,mycond,elecs);
% end





