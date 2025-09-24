function lfps = get_lfp_in_periods(lfp,samplingrate,periods)

lfps=cell(size(periods,1),1);

for c=1:size(periods,1)
    try;
        lfps{c}=lfp(int32(samplingrate*periods(c,1)):int32(samplingrate*periods(c,2)));
    catch;
        c
    end
end;