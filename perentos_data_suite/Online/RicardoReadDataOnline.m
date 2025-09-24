function [data, timestamps, info] = load_open_ephys_data_real_time3subLFP_8ch(foldername,nchannels,nsubchannels,ChLFP)

for i=1:length(nchannels)
    
filename(i,:)=[foldername '100_ADC' num2str(nchannels(i)) '.continuous'];

end

filet=filename(1,:);

filetype = filet(max(strfind(filet,'.'))+1:end); % parse filetype

a=zeros(1,size(nchannels,2));
ResPos=zeros(1,2); 
deLim=[0 0 0;0 0 0];
ind=repmat([1 2 3]',1,length(nchannels));

%DC offsets 

DCoff=[0.0188 0.0306 0.0154 0.0221 0.0131 0.0401 -0.0503 0.0041];


   current_sample = 0;
   
   
    current_sample_r=0;
    
    position=zeros(1,size(nchannels,2));

while 1>0
    
    pause(2^10/400);
    
    for i=1:size(nchannels,2)
        fid(i) = fopen(filename(i,:));
    end
    fseek(fid(1),0,'eof');
    filesize = ftell(fid(1));
    fseek(fid(1),0,'bof');
    % constants
    NUM_HEADER_BYTES = 1024;
    SAMPLES_PER_RECORD = 1024;
    RECORD_SIZE = 8 + 16 + SAMPLES_PER_RECORD*2 + 10; % size of each continuous record in bytes
    RECORD_MARKER = [0 1 2 3 4 5 6 7 8 255]';
    RECORD_MARKER_V0 = [0 0 0 0 0 0 0 0 0 255]';

    % constants for pre-allocating matrices:
    MAX_NUMBER_OF_SPIKES = 1e6;
    MAX_NUMBER_OF_RECORDS = 1e6;
    MAX_NUMBER_OF_CONTINUOUS_SAMPLES = 1e8;
    MAX_NUMBER_OF_EVENTS = 1e6;
    SPIKE_PREALLOC_INTERVAL = 1e6;

    
    %-----------------------------------------------------------------------
    %---------------------- CONTINUOUS DATA --------------------------------
    %-----------------------------------------------------------------------
    
    if strcmp(filetype, 'continuous')
  
        for p=1:size(nchannels,2)
   
            if a(p)==0  
                index = 0;
                PosB=0;
                hdr = fread(fid(p), NUM_HEADER_BYTES, 'char*1');
                eval(char(hdr'));
                info.header = header;
                position(p)=ftell(fid(p));
    
                if (isfield(info.header, 'version'))
                    version = info.header.version;
                else
                    version = 0.0;
                end
            end
            % pre-allocate space for continuous data
            % data = zeros(MAX_NUMBER_OF_CONTINUOUS_SAMPLES, 1);
            info.ts = zeros(1, MAX_NUMBER_OF_RECORDS);
            info.nsamples = zeros(1, MAX_NUMBER_OF_RECORDS);
            data = zeros(MAX_NUMBER_OF_CONTINUOUS_SAMPLES, 1);
            if version >= 0.2
                info.recNum = zeros(1, MAX_NUMBER_OF_RECORDS);
            end
    
            current_sample = 0;
      
            a(p)=a(p)+1;
        
        
       
        
    
            while ftell(fid(p)) + RECORD_SIZE < filesize % at least one record remains
        
                go_back_to_start_of_loop = 0;
                index = index + 1;
                fseek(fid(p),position(p),'bof');
        
                if (version >= 0.1)
                    timestamp = fread(fid(p), 1, 'int64', 0, 'l');
                    nsamples = fread(fid(p), 1, 'uint16',0,'l');
                    if version >= 0.2
                        recNum = fread(fid(p), 1, 'uint16');
                    end
                else
                    timestamp = fread(fid(p), 1, 'uint64', 0, 'l');
                    nsamples = fread(fid(p), 1, 'int16',0,'l');
                end
        
        
                if nsamples ~= SAMPLES_PER_RECORD && version >= 0.1

                    disp(['  Found corrupted record...searching for record marker.']);

                    % switch to searching for record markers

                    last_ten_bytes = zeros(size(RECORD_MARKER));

                    for bytenum = 1:RECORD_SIZE*5

                        byte = fread(fid(p), 1, 'uint8');

                        last_ten_bytes = circshift(last_ten_bytes,-1);

                        last_ten_bytes(10) = double(byte);

                        if last_ten_bytes(10) == RECORD_MARKER(end);

                            sq_err = sum((last_ten_bytes - RECORD_MARKER).^2);

                            if (sq_err == 0)
                                disp(['   Found a record marker after ' int2str(bytenum) ' bytes!']);
                                go_back_to_start_of_loop = 1;
                                break; % from 'for' loop
                            end
                        end
                    end
            
                % if we made it through the approximate length of 5 records without
                % finding a marker, abandon ship.
                if bytenum == RECORD_SIZE*5

                    disp(['Loading failed at block number ' int2str(index) '. Found ' ...
                        int2str(nsamples) ' samples.'])

                    break; % from 'while' loop

                end
                end
        
            if ~go_back_to_start_of_loop

                %fseek(fid(p),position(p),'bof');

                block = fread(fid(p), nsamples, 'int16', 0, 'b'); % read in data

                 %position(p)=ftell(fid(p));

                fread(fid(p), 10, 'char*1'); % read in record marker and discard

                position(p)=ftell(fid(p));

                data(current_sample+1:current_sample+nsamples) = block;

                current_sample = current_sample + nsamples;

                info.ts(index) = timestamp;
                info.nsamples(index) = nsamples;

                if version >= 0.2
                    info.recNum(index) = recNum;
                end

            end
    end
    
 
    
    % crop data to the correct size
    data = data(1:current_sample);
    info.ts = info.ts(1:index);
    info.nsamples = info.nsamples(1:index);
    
    
       
   % current_sample_r=current_sample
    
    if version >= 0.2
        info.recNum = info.recNum(1:index);
    end
    
    % convert to microvolts
    data = data.*info.header.bitVolts;
    
    %buffer data to make smooth concatenations
    if a(p)==1
        
        dataStep{ind(1,p),p}=data;
        Lim(ind(1,p),p)=length(data)/header.sampleRate;
        deLim(ind(1,p),p)=length(data)/header.sampleRate;
        
        dataB=data;
        
    else
        if a(p)<4
        dataStep{ind(1,p),p}=data;
        Lim(ind(1,p),p)=length(dataStep{ind(1,p),p})/header.sampleRate;
        deLim(ind(1,p),p)=sum(Lim(1:ind(1,p),p),1);
        else
           dataStep{ind(1,p),p}=data;
        %Lim(ind(1))=length(dataStep{ind(1)})/header.sampleRate;
        
        for c=1:2
         Lim(c,p)=Lim(c+1,p);
        end
        Lim(3,p)=length(dataStep{ind(1,p),p})/header.sampleRate;
        
        for c=1:3
        deLim(c,p)=sum(Lim(1:c,p)); 
        end
        
        end
    end

        %         if ind(1)==1
%             deLim(ind(1))=length(dataStep{ind(1)})/header.sampleRate;
%         else
%             
%         deLim(ind(1))=length(dataStep{ind(1)})/header.sampleRate+deLim(ind(3));
%         end
        if a(p)==2
        dataB=cat(1,dataStep{1,p},dataStep{2,p});
        else
            if a(p)>2
            dataB=cat(1,dataStep{ind(2,p),p},dataStep{ind(3,p),p},dataStep{ind(1,p),p});
            end
        end
    
       
    ind(:,p)=circshift(ind(:,p),-1);
    
%     timestamps = nan(size(data));
    
%     current_sample = 0;
%     
%     if version >= 0.1
%         
%         for record = 1:length(info.ts)
% 
%             ts_interp = info.ts(record):info.ts(record)+info.nsamples(record);
% 
%             timestamps(current_sample+1:current_sample+info.nsamples(record)) = ts_interp(1:end-1);
% 
%             current_sample = current_sample + info.nsamples(record);
%         end
%     else % v0.0; NOTE: the timestamps for the last record will not be interpolated
%         
%          for record = 1:length(info.ts)-1
% 
%             ts_interp = linspace(info.ts(record), info.ts(record+1), info.nsamples(record)+1);
% 
%             timestamps(current_sample+1:current_sample+info.nsamples(record)) = ts_interp(1:end-1);
% 
%             current_sample = current_sample + info.nsamples(record);
%          end
%         
%     end

%Segment=interp1([1:length(data)]/header.sampleRate,data,[1:round(length(data)/(header.sampleRate/10))]/10);

if a(p)==1
Segment=ButFilter(resample(dataB,10,header.sampleRate),2,1\(10\2),'low');


ResPos(1,p)=length(Segment)-20;

Segment=Segment(21:ResPos(1,p));

if p==ChLFP
    SegmentLFP=resample(dataB,400,header.sampleRate);
ResPosLFP(1,p)=length(SegmentLFP)-20*(400/10);
SegmentLFP=SegmentLFP(20*(400/10)+1:ResPosLFP(1,p));


[y2,f,t]=mtchglong(SegmentLFP,2^10,400,2^10,2^10/2,[],[],[],[0.5 190]);
end

end
    if a(p)==2
        Segment=ButFilter(resample(dataB,10,header.sampleRate),2,1\(10\2),'low');
       

        
ResPos(2,p)=length(Segment)-20;


        Segment=Segment(ResPos(1,p):ResPos(2,p));
      

   if p==ChLFP
        SegmentLFP=resample(dataB,400,header.sampleRate);
        ResPosLFP(2,p)=length(SegmentLFP)-20*(400/10);
       SegmentLFP=SegmentLFP(ResPosLFP(1,p):ResPosLFP(2,p));
        
       [y2,f,t]=mtchglong(SegmentLFP,2^10,400,2^10,2^10/2,[],[],[],[0.5 190]);
   end
    end
        if a(p)==3
     Segment=ButFilter(resample(dataB,10,header.sampleRate),2,1\(10\2),'low');
     
ResPos(3,p)=round(deLim(2,p)*10);

        Segment=Segment(ResPos(2,p):ResPos(3,p));
      
         
%          if p==ChLFP
%              SegmentLFP=resample(dataB,400,header.sampleRate);
%      ResPosLFP(3,p)=round(deLim(2,p)*400);
%    SegmentLFP=SegmentLFP(ResPosLFP(2,p):ResPosLFP(3,p));
%         
%    [y2,f,t]=mtchglong(SegmentLFP,2^10,400,2^10,2^10/2,[],[],[],[0.5 190]);      
%          end
        end
        
  if a(p)>3      
    Segment=ButFilter(resample(dataB,10,header.sampleRate),2,1\(10\2),'low');
   
     
StartS=round(deLim(1,p)*10)+1;

EndS=round(deLim(2,p)*10);

        Segment=Segment(StartS:EndS);
       
        
        if p==ChLFP
              SegmentLFP=resample(dataB,400,header.sampleRate);
            StartSLFP=round(deLim(1,p)*400)+1;
       EndSLFP=round(deLim(2,p)*400);
     SegmentLFP=SegmentLFP(StartSLFP:EndSLFP);
     
        [y2,f,t]=mtchglong(SegmentLFP,2^10,400,2^10,2^10/2,[],[],[],[0.5 190]);      
        end
end
  


if isnan(Segment(end))
    Segment=Segment(1:end-1);
end

     if a(p)==1
    dataplot{p}=Segment;
   
    if p==ChLFP
    totaly2=y2;
    totalt=t+2^10/400/2;
    
    end


 
     else

      lac=length(dataplot{p})/10;  
     
     dataplot{p}=cat(1,dataplot{p},Segment);
  
  % dataplot{p}=cat(2,dataplot{p},ButFilter(interp1([1:length(data)]/header.sampleRate,data',[1:round(length(data)/(header.sampleRate/10))]/10),2,1/(10/2),'low'));

  if p==ChLFP && a(p)~=3
      
        totaly2=cat(1,totaly2,y2);
        
       totalt=cat(1,totalt,(t+2^10/400/2)+lac);
  end
  
  %totaly2(100,20)
  
    length(totalt);
    size(totaly2,1);
%         
    
     end
    
   fclose(fid(p));
    
   end
   

for iplot=1:length(nsubchannels)/2
    
   dataplotsub{iplot}=dataplot{nsubchannels(iplot*2)}-DCoff(nsubchannels(iplot*2))-(dataplot{nsubchannels(iplot*2-1)}-DCoff(nsubchannels(iplot*2-1)));
end

 clear x;
    clear y;
    clear xsub;
    clear ysub;
    
    x=cell(1,length(nchannels));
     y=cell(1,length(nchannels));
     xsub=cell(1,length(nsubchannels)/2);
      ysub=cell(1,length(nsubchannels)/2);
    
      
       for o=1:length(nchannels)
    
    x{o}=[1:length(dataplot{o})]'/10;
   y{o}=dataplot{o}-DCoff(o);
    
    end
      
   
    for o=1:length(nsubchannels)/2
        
   xsub{o}=[1:length(dataplotsub{o})]'/10;
     ysub{o}=dataplotsub{o};
    end
    
    
    if a(p)==1
      
        if length(nchannels)==2
           o=1; 
         ha(1)= subplot(3,1,1);
        recording(:,o)=plot(x{o},y{o},x{o+1},y{o+1});
    
           ha(2)=subplot(3,1,2);
           recordingsub(:,o)=plot(xsub{o},ysub{o});
          
           ha(3)=subplot(3,1,3);
           spectrogram=uimagesc(totalt,f,log(totaly2)');
           axis 'xy'


         linkaxes(ha,'x');
         xlim('auto'); 

        else
        
            colors=[[0 0 1]; [0 1 0]; [1 0 0]; [0 1 1];[1 0 1]; [0 0 0];[0.87 0.49 0]; [0.47 0.67 0.19]];

            ha(1)= subplot(3,1,1);
        for nc=1:length(nchannels)
            hold on;
            recording(:,nc)=plot(x{nc},y{nc},'Color',colors(nc,:));
        end
        
        ha(2)=subplot(3,1,2);
        for nc=1:length(nsubchannels)/2
            hold on;
            recordingsub(:,nc)=plot(xsub{nc},ysub{nc},'Color',colors(nc,:));
        end
          
           ha(3)=subplot(3,1,3);
           spectrogram=uimagesc(totalt,f,log(totaly2)');
         axis 'xy';
           
        linkaxes(ha,'x');
        
         xlim('auto');
        
        end
        
         
     else
        

%         
   for iplot=1:length(nchannels)
 set(recording(iplot),'XData',x{iplot});
 set(recording(iplot),'YData',y{iplot});
      end
       

          for iplot=1:length(nsubchannels)/2
 set(recordingsub(iplot),'XData',xsub{iplot});
 set(recordingsub(iplot),'YData',ysub{iplot}); 
         end




          drawnow
          
  xl=xlim;
  m=xlim('mode');
  
  if strcmp(m,'manual')==1  
  xlim('manual');
  
   ha(3)=subplot(3,1,3);
          spectrogram=uimagesc(totalt,f,log(totaly2)');
           axis xy;
 xlim(xl);
  
  else
 xlim('manual');
 
  ha(3)=subplot(3,1,3);
          spectrogram=uimagesc(totalt,f,log(totaly2)');
           axis xy;
  xlim(xl);
xlim('auto');
 
  end  

  
    end
  

end
end
end

