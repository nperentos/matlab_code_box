function header=load_open_ephys_header(filename)
NUM_HEADER_BYTES = 1024;

fid = fopen(filename);
hdr = fread(fid, NUM_HEADER_BYTES, 'char*1');
eval(char(hdr'));

fclose(fid);
