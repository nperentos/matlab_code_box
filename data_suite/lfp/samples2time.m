function [hours,mins,secs]  = samples2time(samples, samplingfrequency)

t=samples/samplingfrequency;
hours = floor(t / 3600);
t = t - hours * 3600;
mins = floor(t / 60);
secs = t - mins * 60;
    
disp(sprintf('%02d:%02d:%05.2f\n', hours, mins, secs));