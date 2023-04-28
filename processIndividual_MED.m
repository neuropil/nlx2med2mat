function [] = processIndividual_MED(MED_sess_Dir , sessID , sessINFOloc)
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

cd(sessionFolderL)

ticdList = getTicdList(sessionFolderL);

contactNUM = zeros(length(ticdList),1);
NLX_NUM = zeros(length(ticdList),1,'int32');
contactNAME = cell(length(ticdList),1);
contactALL = cell(length(ticdList),1);
fsCon = zeros(length(ticdList),1);
startTime = zeros(length(ticdList),1,'int64');
endTime = zeros(length(ticdList),1,'int64');
sampNUM = zeros(length(ticdList),1,'int64');
ticdName = cell(length(ticdList),1);

for tl = 1:length(ticdList)

    tmpSessI = ticdList{tl};

    readMEDID = [sessionFolderL , filesep , tmpSessI];

    MED_session = read_MED(readMEDID,[],[],[],[],'L2_password');

    disp([num2str(tl), ' out of ', num2str(length(ticdList))])

    NLX_NUM(tl) = MED_session.metadata.acquisition_channel_number;

    tmpContactID = MED_session.channels.metadata.channel_name;

    contactNUM(tl) = str2double(extractAfter(tmpContactID,'_'));

    contactNAME{tl} = extractBefore(tmpContactID,'_'); 

    contactALL{tl} = [tmpContactID , '_' , num2str(NLX_NUM(tl))];

    fsCon(tl) = MED_session.channels.metadata.sampling_frequency;
    startTime(tl) = MED_session.channels.metadata.session_start_time;
    endTime(tl) = MED_session.channels.metadata.session_end_time;
    sampNUM(tl) = MED_session.channels.metadata.absolute_end_sample_number;
    ticdName{tl} = tmpSessI;

end

tabMED_NLX = table(NLX_NUM , contactNAME , contactNUM, ...
    contactALL, fsCon, startTime, endTime, sampNUM, ticdName,...
    'VariableNames',{'NLXn','CNname','CNnum','CNfull','SampFs',...
    'StartT','EndT','SampN','TICDname'});

tabMED_NLXs = sortrows(tabMED_NLX,'NLXn');

% REMOVE ERRONEOUS contacts 
remIND = ~(tabMED_NLXs.NLXn > 192 & tabMED_NLXs.NLXn < 257);
tabMED_NLXsr = tabMED_NLXs(remIND,:);

% FIGURE OUT WIRE NUMBER
endWIRES = [find(diff(tabMED_NLXsr.CNnum) ~= 1) + 1 ; height(tabMED_NLXsr)];
begWIRES = [1 ; endWIRES(1:numel(endWIRES)-1) + 1];

wireID = zeros(height(tabMED_NLXsr),1);
for ebi = 1:height(endWIRES)

    vecFILL = transpose(begWIRES(ebi):endWIRES(ebi));
    wireID(vecFILL) = repmat(ebi,numel(vecFILL),1);

end

tabMED_NLXsr.WireID = wireID;

% FIGURE OUT MACRO MICRO ID
microRows = ~ismember(tabMED_NLXsr.SampFs,8000);
macroCOL = repmat({'macro'},height(tabMED_NLXsr),1);
macroCOL(microRows) = repmat({'micro'},sum(microRows),1);
tabMED_NLXsr.RecID = macroCOL;

% TIME VECTOR
microSamp = tabMED_NLXsr(find(matches(tabMED_NLXsr.RecID,'micro'),1,'first'),:);
macroSamp = tabMED_NLXsr(find(matches(tabMED_NLXsr.RecID,'macro'),1,'first'),:);

microTIME = transpose(int64(linspace(double(microSamp.StartT(1)),...
    double(microSamp.EndT(1)),double(microSamp.SampN(1)))));

macroTIME = transpose(int64(linspace(double(macroSamp.StartT(1)),...
    double(macroSamp.EndT(1)),double(macroSamp.SampN(1)))));

% sess_dataLoc = [mainCaseDir , filesep , 'NWBProcessing\Session_Data'];
cd(sessINFOloc)

load("allSessionData.mat","medInfoTable","medSessionAll");

%%% COLLECTING DATA

medSESSloc = matches(medInfoTable.sessID,sessID);
% medSESSinfo = medInfoTable(medSESSloc,:);
medSESSdat = medSessionAll{medSESSloc};
eventStartTS = medSESSdat.Tstamps(1);
eventEndTS = medSESSdat.Tstamps(numel(medSESSdat.Tstamps));

eventStartTSp = eventStartTS 

int64(1000000*60*3)
% READ in file
% FIRST RECORD TIME preceeding 3 minutes (if available)
% LAST REOCRD succeeding 3 minutes (if available)
% sess.channels.data

% RAW 
cd(sessionFolderL)

for tci2 = 1:height(tabMED_NLXsr)




end



% EXPERIMENT



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
