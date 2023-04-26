function [recs] = NLX2MED_recs(Nlx_events, Nlx_evt_times, MED_session)

    % setup output
    n_nlx_recs = numel(Nlx_events);    
    recs(n_nlx_recs) = struct('nlx_evt', [], 'nlx_time', [], 'med_rec', [], 'med_idx', [], 'med_time', [], 'time_diff', [], 'contiguon', [], 'matched', []);    
    for i = 1:n_nlx_recs
        recs(i).nlx_evt = Nlx_events(i);
        recs(i).nlx_time = int64(Nlx_evt_times(i) * 1e6);
        recs(i).matched = false;
    end

    % get time diff based on first TTL / NlxP event
    n_med_recs = numel(MED_session.records);
    for i = 1:n_med_recs
        if (strcmp(MED_session.records{i}.type_string, 'NlxP'))
            break;
        end
    end
    first_med_NlxP_idx = i;

    for i = 1:n_nlx_recs
        if (strncmp(recs(i).nlx_evt, 'TTL Input', 9))
            break;
        end
    end
    first_nlx_TTL_idx = i;

    nlx2med_time_diff = recs(first_nlx_TTL_idx).nlx_time - MED_session.records{first_med_NlxP_idx}.start_time;

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

end