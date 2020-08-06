% fspace = 100; fs = 500e3;  N = fs/fspace;
% freq_bin = [100:0.5:200]*1e3; 
ofdmmod = comm.OFDMModulator();
ofdmmod.FFTLength = N;
ofdmmod.CyclicPrefixLength = N/5;
ofdmmod.PilotInputPort = true;
ofdmmod.NumGuardBandCarriers = [0;0];
ofdmmod.InsertDCNull = true;
ofdmmod.NumSymbols = numsymbols;
ofdmmod.Windowing = true;
ofdmmod.WindowLength = N/5;
indice = N/2+1-freq_bin/fspace;
subcarrier_indices = [indice';N+2-indice'];
ofdmmod.PilotCarrierIndices = subcarrier_indices;
%%
oi = info(ofdmmod);
datasize = oi.DataInputSize(1);
pilotsize = oi.PilotInputSize(1);