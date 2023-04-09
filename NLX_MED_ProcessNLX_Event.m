function [] = NLX_MED_ProcessNLX_Event(eventFILEdir)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

arguments
    % x (1,:) double
    % y (1,:) double
    eventFILEdir (1,:) char = 'nan';
    % minval (1,1) double = min(min(x),min(y))
end

% User Locates a subject folder .mat setFold file
% UICONFIRM PROMPT TO SELECT RAW FOLDER
if matches(eventFILEdir,'nan')
    rawSEL = uigetdir();
else
    rawSEL = eventFILEdir;
end

cd(rawSEL)
nevDIRa = dir("*.nev");
nevDIRb = {nevDIRa.name};

if isempty(nevDIRb)
    return
end

% Check one folder up for a startUPfold.mat file
eventLOCparts = split(rawSEL,filesep);
oneFoldback = strjoin(eventLOCparts(1:end-1),filesep);

% Cd to one folder back
cd(oneFoldback)
% Check if .mat file is present
matCheck = dir('*.mat');
matCheckn = {matCheck.name};
if isempty(matCheckn) || ~matches('NWB_Process_Folder_Check.mat',matCheckn)
    sessSavLoc = [oneFoldback , filesep , 'Session_Data'];
    nwbSLoc = [oneFoldback , filesep , 'NWB_Data'];
    mkdir(sessSavLoc)
    mkdir(nwbSLoc)
    nwbFilesLOCS.sessSAVloc = sessSavLoc;
    nwbFilesLOCS.nwbSAVloc  = nwbSLoc;
    nwbFilesLOCS.eventLOC   = rawSEL;
    save('NWB_Process_Folder_Check.mat','nwbFilesLOCS')
else
    load('NWB_Process_Folder_Check.mat','nwbFilesLOCS')
end

% DETERMINE IF THERE ARE PREVIOUSLY SAVED Sessions
cd(rawSEL)
logDirA = dir('*.mat');
logDirB = {logDirA.name};

% Check if any mat present
if isempty(logDirB)
    matPresck = 1;
    matNameck = 1;
else
    matPresck = 0;
    % Check if file name is correct
    if contains(logDirB,'EventLogTracker')
        matNameck = 0;
    else
        matNameck = 1;
    end
end

% Both the file is present and has the correct name
if ~matNameck && ~matPresck
    load("EventLogTracker.mat","eventTtable")
    eventLogtab = eventTtable;
elseif matNameck || matPresck
    disp('NO Event LOG file')
    nevLIST = nevDIRb;
    % Create Event log file and save
    [eventLogtab] = createLOGtable(nevLIST);
end

SaveSession = {};
saveSessCount = 1;
% Determine if LOG View should be used
if ~any(eventLogtab.LOGviewed)

    logIndices = find(~eventLogtab.LOGviewed);

    for eli = 1:length(logIndices)

        [EventDat , eventLogtab , userTABLE] = processLOGview(eventLogtab , logIndices(eli));


        % for each unique session in event create an event


        [SaveSession , saveSessCount] = sessionPROCESS(userTABLE , EventDat , SaveSession ,...
            saveSessCount );



    end


    % Export Sessions
    exportSESSIONS(nwbFilesLOCS , SaveSession , eventLogtab);


end









end














function [eventLogtab] = createLOGtable(nevLIST)

EventFnames = transpose(nevLIST);
ViewFile = ones(size(EventFnames),'logical');
ReasonNotV = repmat({''},length(EventFnames),1);
LOGviewed = zeros(size(EventFnames),'logical');
NeuroEvents = repmat({''},length(EventFnames),1);
DateRecord = NaT(size(EventFnames),'TimeZone','America/Denver');
StartTime = NaT(size(EventFnames),'TimeZone','America/Denver');
eventLogtab = table(EventFnames,ViewFile,ReasonNotV,LOGviewed,NeuroEvents,DateRecord,StartTime);

end




function [EventDat , eventLogtab , userTABLE] = processLOGview(eventLogtab , LOGind)

curEvent = eventLogtab.EventFnames{LOGind};

[Timestamps, ~, TTLs, ~, evMessage, evHeader] =...
    Nlx2MatEV(curEvent, [1 1 1 1 1], 1, 1, [] );

% Extract timestamps, TTLs, and header
timestamps = Timestamps;
ttl = TTLs;
header = evHeader;
evText = evMessage;

EventDat.ts = timestamps;
EventDat.ttl = ttl;
EventDat.header = header;
EventDat.tInfo = evText;

% ADD CHECK
if ((length(timestamps) == 1) && timestamps == 0) ||...
        ~(any(contains(evText, {'Starting Recording','ttl'})))

    % Auto advance and populate table
    % 1. Get current log row
    % 2. Get decision
    decision = 'NotUsable';
    viewFFile = false;
    logView = true;

    eventLogtab.ViewFile(LOGind) = viewFFile;
    eventLogtab.ReasonNotV{LOGind} = decision;
    eventLogtab.LOGviewed(LOGind) = logView;

    % 3. Advance
    startRecIuse = [0;0];
    eventsCountuse = [0;0];
    timedurMins = [0;0];
    RecNum = [0;0];

    % Populate table
    varNames = {'Record#','STARTIndex','NumEvents','DurMins'};
    userTABLE = array2table([RecNum , startRecIuse , eventsCountuse,timedurMins],...
        'VariableNames',varNames);

else

    eventLogtab.ViewFile(LOGind) = true;
    eventLogtab.ReasonNotV{LOGind} = '';
    eventLogtab.LOGviewed(LOGind) = true;

    [userTABLE , EventDat] = processEventFile(EventDat);

end


end







function [userTABLE , EventDat  ] = processEventFile(EventDat)

% 1. Determine number of Start Recording fields
startFields = contains(EventDat.tInfo,'Starting Recording');
numRecords = sum(startFields);

% 2. Determine number of TTL flags
startRecInds = find(startFields);
numEventFlags = zeros(size(startRecInds));
timeDUr = zeros(size(startRecInds));
for ttlIbtw = 1:numRecords
    if ttlIbtw == numRecords % This is the last Start Recording file
        numEventFlags(ttlIbtw) = numel(EventDat.tInfo(startRecInds(ttlIbtw)+1:end));
        timeDUr(ttlIbtw) = (EventDat.ts(end) - EventDat.ts(startRecInds(ttlIbtw)))/1000000;
    else
        numEventFlags(ttlIbtw) = (startRecInds(ttlIbtw + 1) - startRecInds(ttlIbtw)) - 1;
        timeDUr(ttlIbtw) = (EventDat.ts(startRecInds(ttlIbtw + 1)) - EventDat.ts(startRecInds(ttlIbtw)))/1000000;
    end
end

% Clean up with respect to duration value - if negative remove
startRecIuse = startRecInds(timeDUr > 0);
eventsCountuse = numEventFlags(timeDUr > 0);
timeDurUse = timeDUr(timeDUr > 0);
timedurMins = round(timeDurUse/60,1);
RecNum = transpose(1:numel(startRecIuse));
% maxRec = max(RecNum);

% Populate table
varNames = {'Record#','STARTIndex','NumEvents','DurMins'};
userTABLE = array2table([RecNum , startRecIuse , eventsCountuse, timedurMins],...
    'VariableNames',varNames);


end







function [SaveSession , saveSessCount] = sessionPROCESS(userTABLE , EventDat,...
    SaveSession , saveSessCount)

sessNUM = length(userTABLE.("Record#"));

if userTABLE.DurMins(1) == 0
    return
end

tmpSession = struct;
for si = 1:sessNUM

    numEVents = userTABLE.NumEvents(si);
    tmpStartI = userTABLE.STARTIndex(si);
    if numEVents == 1
        tmpStopI =  (tmpStartI+numEVents);
    else
        tmpStopI =  (tmpStartI+numEVents)-1;
    end
    % Populate defaults

    % Extract data

    % Check Start index

    if matches(EventDat.tInfo{tmpStartI},'Starting Recording')
        tmpSession.StartIndex(si) = tmpStartI;
    else
        continue
    end

    stopCheck1 = ~matches(EventDat.tInfo{tmpStopI},'Starting Recording');
    stopCheck2 = tmpStopI <= length(EventDat.ts);

    if stopCheck1 && stopCheck2
        tmpSession.StopIndex(si)  = tmpStopI;
    else
        continue
    end

    tmpSession.StartTime(si)  = EventDat.ts(tmpStartI);
    tmpSession.StopTime(si)   = EventDat.ts(tmpStopI);
    tmpSession.StartStr{si}   = EventDat.tInfo{tmpStartI};
    tmpSession.StopStr{si}    = EventDat.tInfo{tmpStopI};

end

% Clean up missing data
remOVEind = cellfun(@(x) ~isempty(x), tmpSession.StartStr, 'UniformOutput',true);
if ~all(remOVEind)
    tmpSession.StartIndex = tmpSession.StartIndex(remOVEind);
    tmpSession.StopIndex = tmpSession.StopIndex(remOVEind);
    tmpSession.StartTime = tmpSession.StartTime(remOVEind);
    tmpSession.StopTime = tmpSession.StopTime(remOVEind);
    tmpSession.StartStr = tmpSession.StartStr(remOVEind);
    tmpSession.StopStr = tmpSession.StopStr(remOVEind);
end

% All other information
tmpSession.SessionInfo = EventDat;
tmpSession.SessType = 'Behavior';
tmpSession.DateRec = convertUNIXtime(EventDat.ts(1));

SaveSession{saveSessCount} = tmpSession;
saveSessCount = saveSessCount + 1;


end








function matdateStr = convertUNIXtime(uniXTimes) % '~' is placeholder for app

matdateStr = NaT(size(uniXTimes),'TimeZone','America/Denver');
for ci = 1:length(uniXTimes)
    timeREcord = datetime(uniXTimes(ci)/1000000,'ConvertFrom',...
        'posixtime','TimeZone','America/Denver');
    matdateStr(ci) = timeREcord;
end

end







function [] = exportSESSIONS(nwbFilesLOCS , SaveSession , eventLogtab)


cd(nwbFilesLOCS.sessSAVloc)
% clean up app.SaveSession
saveSessAll1 = SaveSession(cellfun(@(x) ~isempty(x),...
    SaveSession, 'UniformOutput',true));

% Session file info
eventSaveLoc = nwbFilesLOCS.eventLOC;
sessionSaveLoc = nwbFilesLOCS.sessSAVloc;

% Split Multi sessions for individual Event files
saveSessSplit = cell(length(saveSessAll1)*3,1); % assume each struct will be split 3 times
nC = 1;
for si = 1:length(saveSessAll1)

    tmpSes = saveSessAll1{si};

    if length(tmpSes.StartIndex) == 1
        saveSessSplit{nC} = tmpSes;
        nC = nC + 1;
    else
        for si2 = 1:length(tmpSes.StartIndex)
            if tmpSes.StopIndex(si2) - tmpSes.StartIndex(si2) < 0
                continue
            else
                saveSessSplit{nC}.StartIndex = tmpSes.StartIndex(si2);
                saveSessSplit{nC}.StopIndex = tmpSes.StopIndex(si2);
                saveSessSplit{nC}.StartTime = tmpSes.StartTime(si2);
                saveSessSplit{nC}.StopTime = tmpSes.StopTime(si2);
                saveSessSplit{nC}.StartStr = tmpSes.StartStr{si2};
                saveSessSplit{nC}.StopStr = tmpSes.StopStr{si2};
                saveSessSplit{nC}.SessionInfo = tmpSes.SessionInfo;
                saveSessSplit{nC}.SessType = tmpSes.SessType;
                saveSessSplit{nC}.DateRec = tmpSes.DateRec;
                nC = nC + 1;
            end
        end
    end
end

% clean up app.SaveSession part 2
saveSessAll = saveSessSplit(cellfun(@(x) ~isempty(x),...
    saveSessSplit, 'UniformOutput',true));

% Subject ID
prompt = 'Subject ID';
dlgtitle = 'SUBJECT';
dims = [1 35];
definput = {'SUBJECT_ID'};
subID = inputdlg(prompt,dlgtitle,dims,definput);

% Latest save
tNOW = datetime('now');
% tNOWrd = strrep(tNOW,'-','');
% tNOWfi = strrep(tNOWrd,' ','_');

% Session INFO
sessionINFo.eventLOC = eventSaveLoc;
sessionINFo.sessiLOC = sessionSaveLoc;
sessionINFo.SUBid = subID;
sessionINFo.Created = tNOW;

% Save data
save("allSessionData.mat","saveSessAll","sessionINFo");

% Save table
cd(sessionINFo.eventLOC)
eventTtable = eventLogtab;
save("EventLogTracker.mat","eventTtable");

end
