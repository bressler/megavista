function nSlices = numSlices(vw)%% nSlices = numSlices(view)%% Number of anatomy slices. Use slices(view,scan) to get% the slices for a functional scan.% For volumes/grays, this is a hack that simply returns 1 because% the data are stored in a vector.% For flats, there are 2 slices, one for each hemisphere.% (except across-level flat views, this number is different% in that case).%% djh, 2/21/2001% ras, 10/04, support for flat level view%% jw, 6/2010: Obsolete. Use nSlices = viewGet(vw, 'numSlices') insteadwarning('vistasoft:obsoleteFunction', 'numSlices.m is obsolete.\nUsing\n\tnSlices = viewGet(vw, ''numSlices'')\ninstead.');nSlices = viewGet(vw, 'numSlices');return% % global mrSESSION% % switch view.viewType%     case 'Inplane'%         nSlices = mrSESSION.inplanes.nSlices;%     case {'Volume' 'Gray'}%         nSlices = 1;%     case 'Flat'%         if isfield(view,'numLevels') % acr levels view%             nSlices = 2 + sum(view.numLevels);%         else%             nSlices = 2;%         end% end% % return