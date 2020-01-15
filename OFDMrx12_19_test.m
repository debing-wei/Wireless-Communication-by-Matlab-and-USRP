clear;clc
%% OFDM modulator(pair)
fs = 200e3; T = 0.1;
CarrierNum = fs*T;
% SymbolTime = CarrierNum/fs;
ofdmmod = comm.OFDMModulator();
ofdmmod.FFTLength = CarrierNum;
ofdmmod.NumGuardBandCarriers = [0;0];
ofdmmod.InsertDCNull = false;
ofdmmod.NumSymbols = 1;
%% OFDM demodulator coefficient
ofdmdemod = comm.OFDMDemodulator(ofdmmod);
demod_size = info(ofdmdemod);
len = demod_size.InputSize(1);
%% USRP RX setting
sps = 10;
rx = comm.SDRuReceiver();
rx.CenterFrequency = 0;
rx.DecimationFactor = 500/sps;
rx.SamplesPerFrame = len*sps;
rx.EnableBurstMode = true;
rx.NumFramesInBurst = 10;
%% Detect and Buffer
% release(slog);
slog = dsp.SignalSink;

Threshold = 2.7e8;
searching = true; cnt = 0;
while 1
    seg = rx();
    if sum(abs(double(seg)).^2)<Threshold 
        if searching
            continue;
        else
            break;
        end
    else
        slog(seg); cnt = cnt + 1;
        searching = false;
        if cnt>2
            break;
        end
    end
end
 
rsg = double(slog.Buffer);
plot(real(rsg));
    
%% simulate receive signal
% sps = 10; 
% idle = zeros(985,1);
% tail = zeros(10000,1);
% sig_interp = interp(sig,500);
% sig_dn = downsample(sig_interp,500/sps,8);
% rsg = complex([idle;sig_dn;tail]);
%% timing synchronization
% findhead = 0; h = 1;
for i = 1:2*rx.SamplesPerFrame %rx.SamplesPerFrame
    win1 = rsg([0:15]*sps+i);
    win2 = rsg([len-16:len-1]*sps+i);
    tmp = win1'*win2;
    findhead(i) = tmp;
%     if tmp>findhead
%         findhead = tmp;
%         h = i;
%     end
end
 [~,h] = max(abs(findhead));
 msg_t = downsample(rsg(h:h+(len-1)*sps),sps);
 msg = ofdmdemod(msg_t);
 scatterplot(msg(:,1));grid on