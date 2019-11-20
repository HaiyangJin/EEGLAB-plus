function eg_Table = st_exgaussian(ST_table)

ST_table.Stimuli = cellfun(@(x) x(3:6), ST_table.stimName, 'UniformOutput', false);

[G, ExpCode, Type, Hemisphere, Category, Duration, Stimuli] = findgroups(...
    ST_table.ExpCode, ST_table.Type, ST_table.Hemisphere,...
    ST_table.Category, ST_table.Duration, ST_table.Stimuli);

Count = splitapply(@length, ST_table.MeanAmp, G);

[mu, sigma, tau] = splitapply(@erp_eg_fitplot, ST_table.MeanAmp, G);


eg_table = table(ExpCode, Type, Hemisphere, Category, Duration, Stimuli, Count);

end


% ST_table.SubjCode(strcmp(ST_table.Stimuli, 'n110') & strcmp(ST_table.Category, 'face'))