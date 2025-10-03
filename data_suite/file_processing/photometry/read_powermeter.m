function [p,t] = read_powermeter(fn)
x = dlmread(fn,'\t',4,0);
t = x(:,2);
p = x(:,1);
plot(t/1000,p*1000);
fixfig;
ylabel('Power (mW)');
xlabel('Time (s)');