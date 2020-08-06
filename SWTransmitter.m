%OFDM setup
fspace = 100; fs = 500e3;  N = fs/fspace;
freq_bin = [105:5:200]*1e3; freq_num = length(freq_bin);
%% training
numsymbols=2; %null+ # of training
OFDMModulatorSetup;%datasize,pilotsize * numsymbols
data = zeros(datasize,numsymbols);
rng(0);train = qammod(randi([0 3],freq_num,numsymbols-1),4);
TrainingSymbol = [train; conj(train)];
pilot = [zeros(pilotsize,1) TrainingSymbol];
sig1 = ofdmmod(data,pilot);
clear data pilot
% clear data pilot numsymbols sig
%subcarrier allocation
%first seperate all subcarrier in n group, modulate bits onto subcarrier
%indeces
%%
testsize = 20*10^2;  modindex = 16; M = log2(modindex);
numsymbols = testsize/M/freq_num;
rng(1);
source_bit = randi([0,1],testsize/M,M);
source_sym = bi2de(source_bit);
Txsymbol = qammod(source_sym,modindex);
Txsymbol_parallel = reshape(Txsymbol,freq_num,numsymbols);
OFDMModulatorSetup;%datasize,pilotsize * numsymbols
data = zeros(datasize,numsymbols);
pilot = [Txsymbol_parallel;conj(Txsymbol_parallel)];
sig2 = ofdmmod(data,pilot);
clear pilot data
%% USRP TX
sig = [sig1;sig2];
% plot(sig);
numburst = ceil(length(sig)/5e4);
sig = [sig; zeros(numburst*5e4-length(sig),1)];
% USRPtxSetup;
% sig_m = reshape(sig,5e4,numburst);
% while 1
% for i = 1 : numburst
%     txsig = sig_m(:,i);
%     tx(txsig*20);
% end
% end
% release(tx);

    
