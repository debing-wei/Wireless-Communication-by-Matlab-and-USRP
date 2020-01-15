clear;clc;
%% define USRP
tx = comm.SDRuTransmitter();
tx.CenterFrequency = 0;
tx.InterpolationFactor = 500;
tx.EnableBurstMode = true;
tx.NumFramesInBurst = 10;
%% OFDM coefficient
USRPfs = tx.MasterClockRate/tx.InterpolationFactor;
fs = 200e3; T = 0.1;
CarrierNum = fs*T;
SymbolTime = (CarrierNum+16)/fs;
ofdmmod = comm.OFDMModulator();
ofdmmod.FFTLength = CarrierNum;
ofdmmod.NumGuardBandCarriers = [0;0];
ofdmmod.InsertDCNull = false;
ofdmmod.NumSymbols = 2;
%% OFDM frame (QPSK modilation)
% symbol 1: Time tracking/ First half = Second half
RS = qammod(randi([0,15],CarrierNum/2,1),16);
sym1 = upsample(RS,2);
% symbol 2: data symbol
data = randi([0,15],CarrierNum/2-1,1);
dataMod = qammod(data,16);
sym2 = [0; conj(dataMod(end:-1:1));0;dataMod];
% dataMod(i) is load on subcarrier centered at i*1.25 kHz
% symbol 3: Null symbol
sym3 = zeros(CarrierNum,1);

ofdmFrame = [sym2 sym3];
%% TX
sig = ofdmmod(ofdmFrame);
while 1
    tx(sig*5);
%     pause(0.5);
end

