function [] = prep4NLX_2_MED(rawEventFolder , rawTicdFolder , nlx2matLOC ,...
    readMEDLOC , saveLOC)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

% EXAMPLE

% rawEventFolder = 'E:\TEST_NWB\CLASE001\NWB-data\EventData'
% rawTicdFolder =
% 'E:\TEST_NWB\CLASE001\NWB-data\MEDData\EventData.medd\CSC_0001.ticd'
% nlx2matLOC = 'C:\Users\Admin\Documents\MATLAB\NLX_IO_Code'
% readMEDLOC = 'C:\Users\Admin\DHN\read_MED'
% saveLOC = 'E:\TEST_NWB\CLASE001\NWB-data\EventContig_Data'
% 

addpath(nlx2matLOC)
addpath(genpath(readMEDLOC))

cd(rawEventFolder)
nevdir1 = dir('*.nev');
nevdir2 = {nevdir1.name};

eventSTRINGS = cell(length(nevdir2),1);
eventTIMEstps = cell(length(nevdir2),1);
for ni = 1:length(nevdir2)

    [eventTIMEstps{ni}, ~, ~, ~, eventSTRINGS{ni}, ~] =...
        Nlx2MatEV(nevdir2{ni}, [1 1 1 1 1], 1, 1, []  );

%     [TimeStamps2, ~, ~, ~, EventStrings2, ~] =...
%         Nlx2MatEV( 'Events_0002.nev', [1 1 1 1 1], 1, 1, []  );
% 
end

tposeTST = cellfun(@(x) transpose(x), eventTIMEstps, 'UniformOutput',false);
stackTST =  cell2mat(tposeTST)/1000000;

cd(rawTicdFolder)
session = read_MED('D:\TESTMED\MEDData\EventData.medd\CSC_0001.ticd',[],[],[],[],'L2_password');

% Check number of continuga with the number of start and stops

allEventsEv = vertcat(eventSTRINGS{:});
allEventsTS = stackTST;

% Save out data
cd(saveLOC)



end