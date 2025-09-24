function mergedat(FileList, FileOut, varargin)
%mergedat is a function which merges multiple .dat files from FileList into a single .dat file FileOut.
%This function is a supplementary function for oephys2dat.
%The .dat files to be merged must be in the current directory.
%NOTE: The function also requires for each .dat file an additional file .dat.info with the sampling rate, 
%      number of channels and number of samples in the corresponding .dat file. They are used to validate 
%      the .dat files to be merged. 
%NOTE: The function also creates an ASCII file FileBase.cat.evt with start/stop timestamps (ms) of individual 
%       subsessions in the entire experiment. The first sessions always starts with t=0 (shifted to zero). 
%
%USAGE: mergedat(FileList, FileOut)
%
%INPUT:
% FileList       is a cell vector with a list of .dat files to be merged.
% FileOut        is a name of the output merged .dat file.
%
%OUTPUT:
% FileOut.dat     is a binary .dat file with the wideband signals (mkV).
% FileOut.cat.evt is an ASCII file with with start/stop timestamps (ms) of individual subsessions.
%
%EXAMPLE: mergedat(FileList, 'ER50-20170101.dat')
%
%DEPENDENCIES:
% labbox: DefaultArgs, memorylinux
%
% Evgeny Resnik
% version 12.04.2016




% FileList = {'ER50-20170101-01-hc.dat', 'ER50-20170101-02-tmaze.dat', 'ER50-20170101-03-arena.dat', 'ER50-20170101-04-hc.dat'};
% FileOut = 'ER50-20170101.dat';
% mfilename = 'mergedat';



if nargin<2
    error('USAGE:  mergedat(FileList, FileOut)')
end


% Parse input parameters
% [ChanMapping] = DefaultArgs(varargin,{ [] });


%--------------------------------------------------------------------------------------%
%Size of int16 (bytes)
int16_sizeInBytes = 2;


%Size of the data block (BlockSize x nChan int16) to be loaded at a time (samples)
BlockSize = 2^15;  %(~1 sec at 32kHz)
% BlockSize = 2^25; %(~10 min at 32kHz)
% BlockSize = 2^20; %(~0.5 sec at 32kHz)


%Number of files to process
nFiles = length(FileList);

%Initialize the variables
clear FileBase SubSesID SubSesDescription   



%--------------------------------------------------------------------------------------%
fprintf('Merging .dat files --> %s ...', FileOut)


%Check that all files exist and that channel numbers match match
for k=1:nFiles
    
    %Check whether the given file exists
    if ~exist(FileList{k}, 'file')
        error(sprintf('File %s not found!', FileList{k}))
    end
  
    
    %Accumulate info about files: nChan, nSamples, SamplingRate
    if exist([FileList{k}, '.info'], 'file')
        out = dlmread([FileList{k}, '.info'], '\t');
        nChan(k) = out(1);
        SamplingRate(k) = out(2);
        nSamples(k) = out(3);
        clear out
    else
        error(sprintf('File %s not found!', [FileList{k}, '.info']))
    end
    
        
    %Ensure that the length of the .dat file taken from the corresponding .info file matches
    %the actual length of the .dat file 
    out = dir(FileList{k});
    nSamples_fromFile = out.bytes / int16_sizeInBytes / nChan(k);
    if nSamples(k) ~= nSamples_fromFile
        error(sprintf('Length of %s does not match the value stored in its .info file!', FileList{k}) )
    end
    clear out nSamples_fromFile
    
    
    %Parse file names to extract information about the files
    out = regexp(FileList{k}, '-', 'split');
    FileBase{k}          = [out{1} '-' out{2}];
    SubSesID(k)          = str2num(out{3});
    %SubSesDescription{k} = out{4};
    out2 = regexp(out{4}, '[.]', 'split');
    SubSesDescription{k} = sprintf('%s-%s', out{3}, out2{1});
    clear out out2    
    
end %loop across files



%Check that all files have the same number of channels
if length(unique(nChan))==1
    nChan = nChan(1);
else
    error('Files to be merged have different number of channels!')
end


%Check that all files have the same FileBase
if length(unique(SamplingRate))==1
    SamplingRate = SamplingRate(1);
else
    error('Files to be merged have different sampling rates!')
end


%Check that all files have the same FileBase
if length(unique(FileBase))==1
    FileBase = FileBase{1};
else
    error('Files to be merged have different FileBase!')
end


%Check that all files have different subsession description
if length(unique(SubSesDescription)) ~= length(SubSesDescription)
    error('Files to be merged have repeating subsession descriptions!')
end


%Ensure that subsessions in the provided list are sorted in accordance to their descriptions
[~,ind] = sort(SubSesID);
FileList = FileList(ind);
nSamples = nSamples(ind);
SubSesID = SubSesID(ind);
SubSesDescription = SubSesDescription(ind);
clear ind



%--------------------------------------------------------------------------------------%
%Delete FileOut if already exists 
if exist(FileOut, 'file')
    delete(FileOut)
end


%Copy the very first .dat file from the list to a new FileBase.dat file
[success, msg] = copyfile(FileList{1}, FileOut,'f');
if ~success; error(msg); end


% %OPTION-2: Calculate a size of a data block (samples) depending on available memory
% mem = memorylinux;
% BlockSize = round( 0.5*mem*1e9 / int16_sizeInBytes);
% clear mem 


%Open FileBase.dat for writing (appending more data)
OutFp = fopen(FileOut, 'a');

%Loop across the rest of .dat files
for k=2:nFiles
    
    %read blocks from the given .dat file and append them to FileBase.dat
    InFp  = fopen(FileList{k}, 'r');     
    while(~feof(InFp))  
        Block = fread(InFp, [nChan, BlockSize], 'short');        
        fwrite(OutFp, int16(Block), 'short'); 
    end    
    fclose(InFp);
    
    %Ensure that the length of FileBase.dat is correct
%     nSamples_Must = sum(nSamples(1:k));
%     out = dir(FileOut);
%     nSamples_Actual = out.bytes / int16_sizeInBytes / nChan;
%     if nSamples_Actual ~= nSamples_Must
%         error(sprintf('Length of %s does not match the theoretical value after appending %s!', FileOut, FileList{k}) )
%     end
    clear nSamples_Must nSamples_Actual out
    
end %loop across subsession .dat files


%Close FileBase.dat 
fclose(OutFp);

fprintf('DONE\n')


%--------------------------------------------------------------------------------------%
%Create FileBase.cat.evt file with start/end timestamps (dat samples) of individual subsessions
%It is an ASCII file containing start/stop timestamps (ms, shifted) of individual subsessions in the entire experiment.
%The first sessions always starts with t=0 (shifted to zero). 
%Note: when loaded with the matlab script ParseBhvEpisodes.m timestamps are converted from ms to s! 

FileCatEvtOut = sprintf('%s.%s', FileBase, 'cat.evt');
fprintf('Creating a file %s ...', FileCatEvtOut)
fid = fopen(FileCatEvtOut,'w+');  

for k=1:nFiles
    if k==1       
        t(k,1) = 1;
        t(k,2) = nSamples(k)+1;
    else       
        t(k,1) = t(k-1,2)+1;
        t(k,2) = t(k,1) + nSamples(k);
    end
    
    %convert from dat samples to ms
    t_ms = (t(k,:)-1) ./SamplingRate*10^3;    
    
    %save start/end timestamps into FileBase.cat.evt  
    fprintf(fid, sprintf('%1.6f    beginning of %s-%s-%s\n', t_ms(1), FileBase, SubSesDescription{k}, 'oephys') );
    fprintf(fid, sprintf('%1.6f    end of %s-%s-%s\n', t_ms(2), FileBase, SubSesDescription{k}, 'oephys') );    
    
end %loop across subsessions

fclose(fid);
clear fid t t_ms
fprintf('DONE\n')


return


% %Double-check of the saved time values
% bhv = ParseBhvEpisodes(FileBase);
% round(bhv.time*SamplingRate)+1
% t











