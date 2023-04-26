function [] = processIndividual_MED(MED_sess_Dir , sessID)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here


addpath('C:\Users\Admin\DHN\read_MED\')

cd(MED_sess_Dir)

sessCHCK = checkSessID(MED_sess_Dir , sessID);

if ~sessCHCK
    disp('MEDD files missing or incorrect spelling')
    return
end
sessionFolderL = [MED_sess_Dir , filesep , sessID];

% medSessionAll = cell(length(sessionFolderL),1);
% tmpSession = struct;

%%%% GET ONE TIME VECTOR


%%%% GET column for wire and contact number, wire name, 
%%% NLX number = 1 through 192, 257
%%% contact number = 1 through 16
%%% contact name = LMP
%%% contactNN = LMP_01_257

% Check for unique sample counts 
% Create unique time vector for each when encountered

% Split matrices between micro / macro

% Ignore acquisition values > 192 and < 257


%%%% 


% sessINFOmed = zeros(length(sessionFolderL),7);
% sessID = cell(length(sessionFolderL),1);
% 
% 
% tmpFolder = sessionFolderL{si};
% tmpFolderLoc = [med_dataLoc , filesep , tmpFolder];

cd(sessionFolderL)

ticdList = getTicdList(sessionFolderL);

tsCHECK = zeros(length(ticdList),1,'int32');

for tl = 1:length(ticdList)

    tmpSessI = ticdList{1};

    readMEDID = [sessionFolderL , filesep , tmpSessI];

    MED_session = read_MED(readMEDID,[],[],[],[],'L2_password');

    % typeStringsA = cellfun(@(x) x.type_string, MED_session.records ,'UniformOutput' , false);

    % first_med_Sgmt_idx = find(matches(typeStringsA, 'Sgmt'));

    % channFld = MED_session.channels.metadata;

    % timeSTART = channFld.start_time;
    % timeEND = channFld.end_time;
    % 
    % tsCHECK(tl,1) = timeSTART;
    % tsCHECK(tl,2) = timeEND;
    % 
    disp([num2str(tl), ' out of ', num2str(length(ticdList))])


    tsCHECK(tl) = MED_session.metadata.acquisition_channel_number;




end

% if numel(first_med_Sgmt_idx) > 1
%     first_med_Sgmt_idx = first_med_Sgmt_idx(end);
% end
% 
% first_med_NlxP_idx = first_med_Sgmt_idx + 1;

% % first_med_NlxP_idx = find(matches(typeStringsA, 'NlxP'),1,'first');
% medSessionS = MED_session.records(first_med_NlxP_idx:end);
% 
% typeValue =   cellfun(@(x) x.value,       medSessionS ,'UniformOutput' , true);
% 
% allRecTimes = cellfun(@(x) x.start_time , medSessionS, 'UniformOutput', true);
% 
% sessDurMin_c = ((double(allRecTimes(end))/1000000) - (double(allRecTimes(1))/1000000))/60;
% 
% sessINFOmed(si,1) = si;
% sessINFOmed(si,2) = first_med_NlxP_idx;
% sessINFOmed(si,3) = length(typeStringsA);
% sessINFOmed(si,4) = typeValue(1);
% sessINFOmed(si,5) = typeValue(end);
% sessINFOmed(si,6) = length(medSessionS);
% sessINFOmed(si,7) = sessDurMin_c;
% 
% tmpSession.Tstamps = allRecTimes;
% tmpSession.EventVals = typeValue;
% tmpSession.SessNumber = si;
% 
% medSessionAll{si} = tmpSession;
% sessID{si} = tmpFolder;




% medInfoTable = array2table(sessINFOmed,'VariableNames',{'Session#',...
%     'StartIND_N','StopIND_N','StartName_N','StopName_N','EventCount_N',...
%     'SessMinutes_N'});
% 
% medInfoTable = addvars(medInfoTable,sessID,'Before',"StartIND_N");
% 
% sess_dataLoc = [mainCaseDir , filesep , 'NWBProcessing\Session_Data'];
% cd(sess_dataLoc)
% 
% save("allSessionData.mat","medInfoTable","medSessionAll",'-append');




end




function [sessCHECK] = checkSessID(currentLOC , sessOfInt)

cd(currentLOC)
tmpDir = dir;
folderL1 = {tmpDir.name};
folderL2 = folderL1(~ismember(folderL1,{'.','..'}));
sessList = folderL2;

sessCHECK = matches(sessOfInt,sessList);

end


function [ticdList] = getTicdList(curTICDloc)

cd(curTICDloc)
tmpDir = dir;
folderL1 = {tmpDir.name};
folderL2 = folderL1(~ismember(folderL1,{'.','..'}));

tmpTICDfind = contains(folderL2,'.ticd');
ticdList = folderL2(tmpTICDfind);

end
