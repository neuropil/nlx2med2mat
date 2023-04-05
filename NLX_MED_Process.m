function [] = NLX_MED_Process(eventFILEdir)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

arguments
    % x (1,:) double
    % y (1,:) double
    eventFILEdir (1,1) char = 'nan';
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

% Save Session Loc
sessSaveLoc = nwbFilesLOCS.sessSAVloc;

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
    saveSessCount = 1;

elseif matNameck || matPresck
    disp('NO Event LOG file')
    nevLIST = nevDIRb;
    saveSessCount = 1;
    % Create Event log file and save
    [eventLogtab] = createLOGtable(nevLIST);
end


% Determine if LOG View should be used
if ~any(eventLogtab.LOGviewed)

    logIndices = find(~eventLogtab.LOGviewed);
    LogTasks.logInds = logIndices;

    LogTasks.curNum = 1;
    LogTasks.totalN = numel(logIndices);
    processLOGview(app , logIndices(1))

else % ACTIVATE REST OF GUI

    nevLIST = nevDIRb;
    useEvList = nevLIST(eventLogtab.ViewFile);

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




function processLOGview(eventLogtab , LOGind)

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
    curLOGev = LogTasks.logInds(LogTasks.curNum);
    % 2. Get decision
    decision = 'NotUsable';
    viewFFile = false;
    logView = true;

    eventLogtab.ViewFile(curLOGev) = viewFFile;
    eventLogtab.ReasonNotV{curLOGev} = decision;
    eventLogtab.LOGviewed(curLOGev) = logView;

    % 3. Advance
    startRecIuse = [0;0];
    eventsCountuse = [0;0];
    timedurMins = [0;0];
    RecNum = [0;0];

    % Populate table
    varNames = {'Record#','STARTIndex','NumEvents','DurMins'};
    app.UITable.Data = array2table([RecNum , startRecIuse , eventsCountuse,timedurMins],...
        'VariableNames',varNames);

else

    curLOGev = app.LogTasks.logInds(app.LogTasks.curNum);
    app.eventLogtab.ViewFile(curLOGev) = true;
    app.eventLogtab.ReasonNotV{curLOGev} = '';
    app.eventLogtab.LOGviewed(curLOGev) = true;
    app.SkipEv.Value = 0;
    app.ProcEv.Value = 1;

    processEventFile(app)

end


end




