function [] = createEventTABLE_NLX(mainCaseDir)

% Load in session creation
cd(mainCaseDir)
load("NWB_Process_Folder_Check.mat","nwbFilesLOCS");

sessDIR = nwbFilesLOCS.sessSAVloc;
% eventDIR = nwbFilesLOCS.eventLOC;

cd(sessDIR)
load("allSessionData.mat","saveSessAll")

% Loop through sessions

nlxCheckCell = cell(length(saveSessAll),13);

for si = 1:length(saveSessAll)

    tmpSess = saveSessAll{si};
    nlxCheckCell{si,1} = ['session ',num2str(si)];

    % Process TTL doublets
    [correctSess , sessCheck] = fixProcess(tmpSess);

    if sessCheck

        % StartIndex
        statINDr = tmpSess.StartIndex;
        statINDc = correctSess.indices(1);

        % StopIndex
        stopINDr = tmpSess.StopIndex;
        stopINDc = correctSess.indices(end);

        % StartName
        statNMr = tmpSess.StartStr;
        statNMc = correctSess.events(1);

        % StopName
        stopNMr = tmpSess.StopStr;
        stopNMc = correctSess.events(end);

        % Event number %%%% PROCESS
        stopEvCr = stopINDr - statINDr;
        stopEvCc = numel(correctSess.events);

        % Session Duration
        sessDurMin_r = ((tmpSess.StopTime/1000000) - (tmpSess.StartTime/1000000))/60;
        sessDurMin_c = ((correctSess.Tstamps(end)/1000000) - (correctSess.Tstamps(1)/1000000))/60;

        nlxCheckCell{si,2} = statINDr;
        nlxCheckCell{si,3} = stopINDr;
        nlxCheckCell{si,4} = statNMr;
        nlxCheckCell{si,5} = stopNMr;
        nlxCheckCell{si,6} = stopEvCr;
        nlxCheckCell{si,7} = sessDurMin_r;

        nlxCheckCell{si,8} = statINDc;
        nlxCheckCell{si,9} = stopINDc;
        nlxCheckCell{si,10} = statNMc;
        nlxCheckCell{si,11} = stopNMc;
        nlxCheckCell{si,12} = stopEvCc;
        nlxCheckCell{si,13} = sessDurMin_c;

    else
        continue
    end


end

nlxInfoTable = cell2table(nlxCheckCell,'VariableNames',{'Session#','StartIND_O',...
    'StopIND_O','StartName_O','StopName_O','EventCount_O','SessMinutes_O',...
    'StartIND_N','StopIND_N','StartName_N','StopName_N','EventCount_N',...
    'SessMinutes_N'});

save("allSessionData.mat","nlxInfoTable",'-append');


end



function [correctStruct , sessCheck] = fixProcess(tmpSession)


% Check session validity
sessionOff = tmpSession.StopIndex - tmpSession.StartIndex;
sessMin = ((tmpSession.StopTime/1000000) - (tmpSession.StartTime/1000000))/60;

if sessionOff < 5 || sessMin < 1.5
    sessCheck = 0;
    correctStruct = nan;
    return
else
    sessCheck = 1;
end


allstrings = tmpSession.SessionInfo.tInfo;
sessStrings = allstrings(tmpSession.StartIndex:tmpSession.StopIndex);
sessTS = tmpSession.SessionInfo.ts(tmpSession.StartIndex:tmpSession.StopIndex);
currentINDS = tmpSession.StartIndex:tmpSession.StopIndex;

hexSTRingsLog = contains(sessStrings,'TTL');

sessStringsHex = sessStrings(hexSTRingsLog);
currentINDS_2 = currentINDS(hexSTRingsLog);
sessTS_2 = sessTS(hexSTRingsLog);

% Get HeX flags
hexExtract = extractBetween(sessStringsHex,'(',')');
hexConvert = hex2dec(hexExtract);

% Remove all 0s
zeroRem = hexConvert ~= 0;

% Events
eventsCorrect = hexConvert(zeroRem);
% Indicies
currentINDS_c = transpose(currentINDS_2(zeroRem));
% TS
sessTS_c= transpose(sessTS_2(zeroRem));

correctStruct.events = eventsCorrect;
correctStruct.indices = currentINDS_c;
correctStruct.Tstamps = sessTS_c;

end




















