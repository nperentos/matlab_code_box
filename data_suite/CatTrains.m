%function [Train, Group, GroupsId, OrigInd] = CatTrains(Trains, Groups, Periods, IfIn)
% Trains = cell array {Res1,Res2,Res3} , Groups  = {Clu1,Clu2,Clu3}
function [Train, Group, GroupsId] = CatTrains(Trains, Groups, varargin)
[Periods, IfIn] = DefaultArgs(varargin,{[],0});

nTrains = length(Trains);
nGroups = length(Groups);
if (nTrains~=nGroups)
    error('number of traisn and number of groups vectors should be the same');
    exit(1);
end

Index=[];
nPlots=1;
for t=1:nTrains
    if length(Groups{t})<2
        Groups{t} = ones(length(Trains{t}),1)*nPlots;
        Index = [Index ; t];
        nPlots=nPlots+1;
    else
        ThisGroup = unique(Groups{t});
        nThisGroup = length(ThisGroup);
        Index = [Index ; ThisGroup];
        tmpGroup=[];
        for g=1:nThisGroup
            tmpGroup(find(Groups{t}==ThisGroup(g))) = g + nPlots - 1;
        end
        nPlots=nPlots+nThisGroup;
        Groups{t}=tmpGroup(:);
    end

end

Train = []; Group =[];

for t=1:nTrains

    Train = [Train ; Trains{t}];
    Group = [Group ; Groups{t}];

end
if ~isempty(Periods)
    [Train Ind ] = SelectPeriods(Train, Periods, 'd', IfIn);
    Group = Group(Ind);

%     [Train si] = sort(Train);
%     Group = Group(si);

end
GroupsId = unique(Group);

