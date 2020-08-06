fspace = 100; fs = 500e3;  N = fs/fspace;
freq_bin = [105:5:200]*1e3; freq_num = length(freq_bin); testsize=2e3;
modindex = 16; M = log2(modindex);
numsymbols = testsize/M/freq_num+1;
%% receive signal
RXSigdetect;

%% processing
% nnn = [];
% for i = 49620-100 : 49620+100
freq_num = length(freq_bin);
rxsig = sig(idx:idx-1+numsymbols*6000);
OFDMDemodulatorSetup;
[~,pilot_r] = ofdmdemod(rxsig);
%% Equalizer
train_r = pilot_r(1:freq_num,1);
load = pilot_r(1:freq_num,2:numsymbols);
rng(0);train = qammod(randi([0 3],freq_num,1),4);
load_equalized = load.*train./train_r;
message = qamdemod(load_equalized,16);
message_bit = de2bi(message);
%% BER
rng(1);
source_bit = randi([0,1],testsize/M,M);
[num,ratio] = biterr(message_bit,source_bit)
% nnn= [nnn num];
% end