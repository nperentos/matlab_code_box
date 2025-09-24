function [out] = getEvents(ch,tp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this a renaming function for getRewards(ch,tp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Takes input as the reward pulses continuous channel and returns the
% location of reward points in the lfp array. There are three kinds of
% pulses whic all appear together every time the animal reaches the reward
% point. The first gives the time of the sound stimulus, the second gives
% the time of the pump reward delivery and the third is a long pulse that
% gives the delay time during which the carousel is locked at the starting
% point while the animal is consuming the reward. 
% Now also takes input a variable that defines the type of events to search
% for
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[out] = getRewards(ch,tp);