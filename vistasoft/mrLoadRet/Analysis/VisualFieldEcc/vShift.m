function mtxShifted = vShift ( mtx, offset )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% function mtxShifted = vShift ( mtx, offset )%% DESCRIPTION%   Non-circular shift; NaNs for areas that are 'new'%   Non-circular shift 2D matrix samples by OFFSET (a [Y,X] 2-vector),%   such that  RES(POS) = MTX(POS-OFFSET).%% INPUT   %   see description%% OUTPUT / RESULTS %   shifted matrix%% BASED ON: %% AUTHOR:%   Volker Maximillian Koch%   vk@volker-koch.de%% DATE:%   January - June 2001%% REFERENCE:%% COMMENTS:%% SEE ALSO:%% TO-DO:%% Update History:%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mtxShifted = shift(mtx,offset);mtxSize = size(mtx);
if offset(1) >=0 offset(1) = mod(offset(1),mtxSize(1)); else  offset(1) = -mod(-offset(1),mtxSize(1)); end;
if offset(2) >=0 offset(2) = mod(offset(2),mtxSize(2)); else  offset(2) = -mod(-offset(2),mtxSize(2)); end;
mtxShifted(: , 1:offset(2)) = NaN;mtxShifted(: , mtxSize(2)+offset(2)+1:mtxSize(2)) = NaN;mtxShifted(1:offset(1) , :) = NaN;mtxShifted(mtxSize(1)+offset(1)+1 :mtxSize(1) , :) = NaN;return;