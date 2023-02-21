%%

% NEV read: C:\Users\Admin\Documents\Github\NLX-Event-Viewer\NLX_IO_Code
% read MED: C:\Users\Admin\DHN\read_MED



%% 
testNEV = 'E:\TEST_NWB\CLASE001\NWB-data\EventData';

testMED = 'E:\TEST_NWB\CLASE001\NWB-data\MEDData\EventData.medd';

%%
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
session = read_MED('E:\TEST_NWB\CLASE001\NWB-data\MEDData\EventData.medd\CSC_0001.ticd',[],[],[],[],'L2_password');