%%

% NEV read: C:\Users\Admin\Documents\Github\NLX-Event-Viewer\NLX_IO_Code
% read MED: C:\Users\Admin\DHN\read_MED
name = getenv('COMPUTERNAME');

switch name
    case 'DESKTOP-FAGRV5G'
        testNEV = 'D:\TESTMED\EventData';
        testMED = 'D:\TESTMED\MEDData\EventData.medd';
    case 'Blah'
        testNEV = 'E:\TEST_NWB\CLASE001\NWB-data\EventData';
        testMED = 'E:\TEST_NWB\CLASE001\NWB-data\MEDData\EventData.medd';
end




%% 


%%
cd(testNEV)
[TimeStamps1, EventIDs1, TTLs1, Extras1, EventStrings1, Header1] =...
    Nlx2MatEV( 'Events_0001.nev', [1 1 1 1 1], 1, 1, []  );

[TimeStamps2, EventIDs2, TTLs2, Extras2, EventStrings2, Header2] =...
    Nlx2MatEV( 'Events_0002.nev', [1 1 1 1 1], 1, 1, []  );

[TimeStamps3, EventIDs3, TTLs3, Extras3, EventStrings3, Header3] =...
    Nlx2MatEV( 'Events_0003.nev', [1 1 1 1 1], 1, 1, []  );

[TimeStamps4, EventIDs4, TTLs4, Extras4, EventStrings4, Header4] =...
    Nlx2MatEV( 'Events_0004.nev', [1 1 1 1 1], 1, 1, []  );

%%
totalNEV = length(EventIDs1) + length(EventIDs2) + length(EventIDs3) + length(EventIDs4);

%%
session = read_MED('D:\TESTMED\MEDData\EventData.medd\CSC_0001.ticd',[],[],[],[],'L2_password');

%%

allstrings = cell(length(session.records),1);
for i = 1:numel(session.records)
    type_string = session.records{i}.type_string;
    allstrings{i} = type_string;
    %
    %     switch type_string
    %         case 'Sgmt'
    %             disp(['Description: ' sess.records{i}.description]);
    %         case 'NlxP'
    %             disp(['Start Time: ' sess.records{i}.start_time_string]);
    %         case 'Note'
    %             disp(['Text: ' sess.records{i}.text]);
    %     end
    %     disp(newline);
end

%%  Check number of continuga with the number of start and stops

allEventsEv = [EventStrings1 ; EventStrings2 ; EventStrings3 ; EventStrings4];
allEventsTS = [TimeStamps1' ; TimeStamps2' ; TimeStamps3' ; TimeStamps4']/1000000;
allEventsTSst = allEventsTS(matches(allEventsEv,'Starting Recording'));
diST = diff(allEventsTSst);
diST2 =  sum(diST > 0)

allEventsTSstp = allEventsTS(matches(allEventsEv,'Stopping Recording'));
diSTP = diff(allEventsTSstp);
diSTP2 =  sum(diSTP > 0)


numContingua = height(session.contigua);

% Get indices for starts

offTsec = round(diff(allEventsTSst)*32000);


























