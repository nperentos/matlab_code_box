function AssignNeuronalType(FileBase)

load([FileBase '.UnitsThetaModulation.RUN.mat'])
load([FileBase '.ComputeBurstiness.mat'])

for i=1:length([out.cids])
    
    Clu = out(i).cids;
    nqIndex = find(burstiness.cids==Clu);
    
    out(i).burstiness = burstiness.Burstiness(nqIndex);
    
    if (contains(out(i).Layer,'DG'))
        if (out(i).quality.SpkWidthR<0.55)
            out(i).NeuronalType = 'n-I';
        else
            if burstiness.Burstiness(nqIndex)>0.6
                out(i).NeuronalType = 'E';
            else
                out(i).NeuronalType = 'w-I';
            end
        end
    else
        out(i).NeuronalType = 'N/A';
    end
    
end

save([FileBase '.' mfilename '.mat'],'out');

end