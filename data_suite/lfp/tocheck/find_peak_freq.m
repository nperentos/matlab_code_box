% Find main frequency mode during freezing
function peak_freq = find_peak_freq(lfp,samplingrate, freeze, longestfreezing)

if nargin<3 || isempty(longestfreezing); longestfreezing = 1; end;

if nargin<2 || isempty(freeze); freeze = []; end;
 

if ~isempty(freeze);
    if longestfreezing;
        % Find longest freezing episode
        [m,idx]=max(freeze(:,2)-freeze(:,1));
        long_freeze = lfp(int32(freeze(idx,1)*samplingrate):int32(freeze(idx,2)*samplingrate));
    else
        long_freeze = lfp(int32(freeze(1,1)*samplingrate):int32(freeze(1,2)*samplingrate));
    end;
else 
    long_freeze = lfp;
end;

[S,t,f]=calculate_spectrogram(long_freeze,samplingrate,'windowsize',2,'overlap',95,'log','off','fpass',[1 12],'nw',7); 
[m,idx]=max(S,[],2);
peak_freq = mean(f(idx));