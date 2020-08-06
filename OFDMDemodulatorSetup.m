% fspace = 100; fs = 500e3;  N = fs/fspace;
% freq_bin = [100:0.5:200]*1e3; numsymbols
% numsymbols = 251
OFDMModulatorSetup;
ofdmdemod = comm.OFDMDemodulator(ofdmmod);