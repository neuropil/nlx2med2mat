%% STEPS FOR PROCESSING NLX and MED

%% STEP 1

% Create Event folder with all recorded CSC files
% Note - current setup only allows for 192 macro channels
% Note - micro recordings currently start at channel 257
% Note - 193 - 256 CSC files should be deleted from the raw Event folder
% Note - check micro-wire channel count to determine how many channels
% greater than 257 should be deleted - currently only a maximum of 16 are
% used

% Create a MED_Processing folder with all recorded MED sessions (ticd
% folders)

% Make sure NLX_IO_Code folder is on the path


%% STEP 2 run NLX_MED_ProcessNLX_Event.m

% eventfolder = 'C:\WITH EVENTS';

% NLX_MED_ProcessNLX_Event(eventfolder)

eventfolder = 'Y:\PatientData_MW\MW22\NWBProcessing\EventFiles';

NLX_MED_ProcessNLX_Event(eventfolder);


%% STEP 3 run createEventTABLE_NLX.m

% mainCaseFolder = 'C:\CaseFolder\NWBprocessing'; % would have Event folder in this
% folder

% createEventTABLE_NLX(mainCaseFolder)


mainCaseFolder = 'Y:\PatientData_MW\MW22\NWBProcessing';
createEventTABLE_NLX(mainCaseFolder)


%% STEP 4 run createEventTABLE_MED.m

% mainCaseFolder = 'C:\CaseFolder'; % would have MED_Processing folder in this
% folder

% createEventTABLE_MED(mainCaseFolder)


mainCaseFolder = 'Y:\PatientData_MW\MW22';
createEventTABLE_MED(mainCaseFolder)