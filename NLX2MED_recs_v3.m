function [outTABLE3] = NLX2MED_recs_v3(Nlx_events, Nlx_evt_times, MED_session)

    outTABLE = table(Nlx_events , Nlx_evt_times,'VariableNames',{'NLX_Events' , 'NLX_Times'});
    outTABLE.MED_REC = cell(height(Nlx_events),1);
    outTABLE.MED_IND = nan(height(Nlx_events),1);
    outTABLE.MED_TIME = zeros(height(Nlx_events),1,"int64");
    outTABLE.TIME_DIFF = zeros(height(Nlx_events),1,"int64");
    outTABLE.contiguon = zeros(height(Nlx_events),1);
    outTABLE.NLX_Times = int64(outTABLE.NLX_Times * 1e6);

    % get time diff based on first TTL / NlxP event
    typeStrings = cellfun(@(x) x.type_string,MED_session.records ,'UniformOutput' , false);
    first_med_NlxP_idx = find(matches(typeStrings, 'NlxP'),1,'first');

    first_nlx_TTL_idx = find(contains(outTABLE.NLX_Events,'TTL Input'),1,'first');

    nlx2med_time_diff = outTABLE.NLX_Times(first_nlx_TTL_idx) -...
        MED_session.records{first_med_NlxP_idx}.start_time;

    % Remove duplicates STARTING
    startrecIndices = find(matches(outTABLE.NLX_Events,'Starting Recording'));
    startrecTimes = outTABLE.NLX_Times(startrecIndices);
    startOffs = diff(startrecTimes);
    startOffsW = [startOffs ; 5001];
    startOffsW2 = abs(startOffsW);
%     keepStartIndices = startrecIndices(startOffsW > 0);
    removStartIndices = startrecIndices(startOffsW2 < 5000);
    outTABLE2 = outTABLE;
    outTABLE2(removStartIndices,:) = [];

    % Remove duplicates STOPPING
    stoprecIndices = find(matches(outTABLE2.NLX_Events,'Stopping Recording'));
    stoprecTimes = outTABLE2.NLX_Times(stoprecIndices);
    stopOffs = diff(stoprecTimes);
    stopOffsW = [stopOffs ; 5001];
    stopOffsW2 = abs(stopOffsW);
%     keepStartIndices = startrecIndices(startOffsW > 0);
    removStopIndices = stoprecIndices(stopOffsW2 < 5000);
    outTABLE3 = outTABLE2;
    outTABLE3(removStopIndices,:) = [];

    % All med times
    allConStarts = transpose([MED_session.contigua.start_time]);
    allConEnds = transpose([MED_session.contigua.end_time]);
    allConStartsNLXof = allConStarts + nlx2med_time_diff;
    allConEndsNLXof = allConEnds + nlx2med_time_diff;
    allRecTimes = cellfun(@(x) x.start_time , MED_session.records, 'UniformOutput', true);
    allMEDRecsof = allRecTimes + nlx2med_time_diff;

   

% 8 to 10 3500
% switch through start , stop and port events
typeAll = {'start','stop','ttl'};
for typeI = 1:3

    switch typeAll{typeI}
        case 'start'
            startINDs = find(matches(outTABLE3.NLX_Events,'Starting Recording'));
            for si = 1:length(startINDs)
                tmpStartIND = outTABLE3.NLX_Times(startINDs(si));
                [~,continguID] = min(abs(tmpStartIND - allConStartsNLXof));
                outTABLE3.contiguon(startINDs(si)) = continguID;
                timeDIFF = tmpStartIND - allConStartsNLXof;
                outTABLE3.TIME_DIFF(startINDs(si)) = timeDIFF(continguID);
                outTABLE3.MED_TIME(startINDs(si)) = MED_session.contigua(continguID).start_time;
                outTABLE3.MED_REC{startINDs(si)} = 'contiguon entry';
            end
        case 'stop'
            stopINDs = find(matches(outTABLE3.NLX_Events,'Stopping Recording'));
            for si = 1:length(stopINDs)
                tmpStopIND = outTABLE3.NLX_Times(stopINDs(si));
                [~,continguID] = min(abs(tmpStopIND - allConEndsNLXof));
                outTABLE3.contiguon(stopINDs(si)) = continguID;
                timeDIFF = tmpStopIND - allConEndsNLXof;
                outTABLE3.TIME_DIFF(stopINDs(si)) = timeDIFF(continguID);
                outTABLE3.MED_TIME(stopINDs(si)) = MED_session.contigua(continguID).end_time;
                outTABLE3.MED_REC{stopINDs(si)} = 'contiguon entry';
            end
        case 'ttl'
            ttlINDs = find(contains(outTABLE3.NLX_Events,'TTL Input'));
            for si = 1:length(ttlINDs)
                tmpttlIND = outTABLE3.NLX_Times(ttlINDs(si));
                [timeDIFFmed,medIDX] = min(abs(tmpttlIND - allMEDRecsof));
                outTABLE3.TIME_DIFF(ttlINDs(si)) = timeDIFFmed;
                outTABLE3.MED_TIME(ttlINDs(si)) = MED_session.records{medIDX}.start_time;
                outTABLE3.MED_REC{ttlINDs(si)} = MED_session.records{medIDX}.type_string;
                outTABLE3.MED_IND(ttlINDs(si)) = medIDX;

                %%%% DEAL WITH CONTINGUA
                %   outTABLE3.contiguon(stopINDs(si)) = continguID;
            end
    end


end







end