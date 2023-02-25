function [recs] = NLX2MED_recs_v2(Nlx_events, Nlx_evt_times, MED_session)

    % setup output
    n_nlx_recs = numel(Nlx_events);    
    recs(n_nlx_recs) = struct('nlx_evt', [], 'nlx_time', [], 'med_rec', [], 'med_idx', [], 'med_time', [], 'time_diff', [], 'contiguon', [], 'matched', []);    
    for i = 1:n_nlx_recs
        recs(i).nlx_evt = Nlx_events(i);
        recs(i).nlx_time = int64(Nlx_evt_times(i) * 1e6);
        recs(i).matched = false;
    end

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

    tmpStart = outTABLE2.NLX_Times(1);

    [~,continguID] = min(abs(tmpStart - allConStartsNLXof));



    med_idx = 1;
    nlx_idx = 1;
    contig_idx = 1;
    while (nlx_idx <= n_nlx_recs)
        % check for recording start
        if (strncmp(recs(nlx_idx).nlx_evt, 'Starting Recording', 18))
            time_diff = recs(nlx_idx).nlx_time - (MED_session.contigua(contig_idx).start_time + nlx2med_time_diff);
            while (abs(time_diff) > 5000)  % 5 ms
                contig_idx = contig_idx + 1;
                time_diff = recs(nlx_idx).nlx_time - (MED_session.contigua(contig_idx).start_time + nlx2med_time_diff);
            end
            % match to contiguon
            recs(nlx_idx).med_rec = 'contiguon entry';
            recs(nlx_idx).med_idx = [];
            recs(nlx_idx).med_time = MED_session.contigua(contig_idx).start_time;
            recs(nlx_idx).time_diff = time_diff;
            recs(nlx_idx).contiguon = contig_idx;
            recs(nlx_idx).matched = true;
            nlx_idx = nlx_idx + 1;
            % see if there is a duplicate
            if (strncmp(recs(nlx_idx + 1).nlx_evt, 'Starting Recording', 18))
                time_diff = recs(nlx_idx + 1).nlx_time - (MED_session.contigua(contig_idx).start_time + nlx2med_time_diff);
                if (abs(time_diff) < 5000) % 5 ms
                    recs(nlx_idx).med_rec = 'contiguon entry';
                    recs(nlx_idx).med_idx = [];
                    recs(nlx_idx).med_time = MED_session.contigua(contig_idx).start_time;
                    recs(nlx_idx).time_diff = time_diff;
                    recs(nlx_idx).contiguon = contig_idx;
                    recs(nlx_idx).matched = true;
                    nlx_idx = nlx_idx + 1;
                end
            end
            continue;
        end

        % check for recording end
        if (strncmp(recs(nlx_idx).nlx_evt, 'Stopping Recording', 18))
            time_diff = recs(nlx_idx).nlx_time - (MED_session.contigua(contig_idx).end_time + nlx2med_time_diff);
            % match to contiguon
            recs(nlx_idx).med_rec = 'contiguon exit';
            recs(nlx_idx).med_idx = [];
            recs(nlx_idx).med_time = MED_session.contigua(contig_idx).end_time;
            recs(nlx_idx).time_diff = time_diff;
            recs(nlx_idx).contiguon = contig_idx;
            recs(nlx_idx).matched = true;
            nlx_idx = nlx_idx + 1;
            % see if there is a duplicate
            if (nlx_idx < n_nlx_recs)
                if (strncmp(recs(nlx_idx + 1).nlx_evt, 'Stopping Recording', 18))
                    time_diff = recs(nlx_idx + 1).nlx_time - (MED_session.contigua(contig_idx).start_time + nlx2med_time_diff);
                    if (abs(time_diff) < 5000) % 5 ms
                        recs(nlx_idx).med_rec = 'contiguon entry';
                        recs(nlx_idx).med_idx = [];
                        recs(nlx_idx).med_time = MED_session.contigua(contig_idx).end_time;
                        recs(nlx_idx).time_diff = time_diff;
                        recs(nlx_idx).contiguon = contig_idx;
                        recs(nlx_idx).matched = true;
                        nlx_idx = nlx_idx + 1;
                    end
                end
            end
            continue;
        end

       time_diff = recs(nlx_idx).nlx_time - (MED_session.records{med_idx}.start_time + nlx2med_time_diff);
       if (time_diff == 0)
            recs(nlx_idx).med_rec = MED_session.records{med_idx}.type_string;
            recs(nlx_idx).med_idx = med_idx;
            recs(nlx_idx).med_time = MED_session.records{med_idx}.start_time;
            recs(nlx_idx).time_diff = time_diff;
            recs(nlx_idx).contiguon = contig_idx;
            recs(nlx_idx).matched = true;
            med_idx = med_idx + 1;
            nlx_idx = nlx_idx + 1;
        elseif (time_diff < 0)
            nlx_idx = nlx_idx + 1;
        else
            med_idx = med_idx + 1;            
        end
    end

    

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


resEvents = transpose([recs.nlx_evt]);
stst1 = matches(resEvents,{'Stopping Recording','Starting Recording'});
redTABLE = table(transpose([recs(stst1).nlx_evt]) , transpose([recs(stst1).nlx_time]),...
    transpose([recs(stst1).time_diff]) , transpose([recs(stst1).contiguon]),'VariableNames',...
    {'NLXevent','NLXtime','timeDiff','ContigN'});


stst2 = matches(outTABLE3.NLX_Events,{'Stopping Recording','Starting Recording'});
finTABLE = outTABLE3(stst2,[1,2,6,7]);

%     contigCount = 1;
%     for ni = 1:height(outTABLE3)
% 
%         tmpNLXev = outTABLE3.NLX_Events{ni};
% 
%         switch tmpNLXev
%             case 'Starting Recording'
%                 
%                 time_diff = outTABLE3.NLX_Times(ni) - (MED_session.contigua(contigCount).start_time + nlx2med_time_diff);
% 
%             case 'Stopping Recording'
% 
% 
% 
%             otherwise
% 
% 
%         end
% 
% 
% 
% 
%     end


test = 1;







end