function duplicateDataType(view,newName);%     duplicateDataType(view,[newName]);% % Duplicate the current datatype as a new datatype,then updates all open views appropriately.% This routine depends on dataTYPES being a global variable.%% Input: newName: a char string%   when not given, pops out input dialog to ask user input the new datatype name.%% JL, 11/2004mrGlobalscurDataType = viewGet(view,'curDataType');saveQuery  = 0;% automatically save if newName is given using               % commandline intputif ~exist('newName','var'); % user input for a non-empty name    saveQuery = 1;    newName = [];    dlg = 'Please give a new name for the new datatype';    while isempty(newName);        newName = inputdlg(dlg,'Name new datatype');        if iscell(newName)&~isempty(newName);            newName = deblank(newName{1}); % remove possible blanks            if existDataType(newName);                dlg = 'What you just input is already in dataTYPES. Try again !!!';                newName = []; disp(['Warning: ',dlg]);            end        else            dlg = 'You MUST give a NEW name for the new datatype !!!';            disp(['Warning: ',dlg]);        end;    endelseif ~ischar(newName);    error('duplicateDataType: input newName is not a char string');end%Now add the new datatype to the enddataTYPES(end+1) = dataTYPES(curDataType);dataTYPES(end).name = newName;saveSession(saveQuery);% now actually duplicate (all) files:oldDir = dataDir(view);newDir = fullfile(fileparts(oldDir),newName);copyfile(oldDir,newDir);disp('datatype duplicated and renamed. Saved.');% Loop through the open views, switch their curDataType appropriately, % and update the dataType popupsndataType = length(dataTYPES);INPLANE = resetDataTypes(INPLANE,ndataType);VOLUME = resetDataTypes(VOLUME,ndataType);FLAT = resetDataTypes(FLAT,ndataType);return;%%%%% Now here, mimicry removeDataType.m, we use a private copy of% resetDataTypes here. This is certainly not a good habit as you have many% versions of resetDataTypes hiding somewhere. Fix later -- Junjiefunction viewList=resetDataTypes(viewList,ndataType)% Loops through the views, changing the dataType appropriately.% The call to selectDataType updates the dataType popup.for s=1:length(viewList)    if ~isempty(viewList{s})         viewList{s} = selectDataType(viewList{s},1);         viewList{s} = selectDataType(viewList{s},ndataType);     endendreturn