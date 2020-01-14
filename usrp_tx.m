tx = comm.SDRuTransmitter(...
              'Platform','X310', ...
              'IPAddress','192.168.10.2', ...
              'CenterFrequency',120e3, ...
              'Gain', 0, ...
              'MasterClockRate', 120e6, ...
              'InterpolationFactor',500);
 %%         
 fs = 5e3; sps = 20;
 p_len = 1e3;
 h_len =26;
 t_len = 1+1;
 
 Header1 = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'*(3+3i);
 Header2 = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'*(3-3i);
 Header = [Header1; Header2];
 %%
 pic = 2; txt = 1;
 msg_type = qammod(2,16);
 %%
 img=rgb2gray(imread('shasta' ,'jpg'));
 img = imresize(img,[100 100]);
 img = floor(img/16-1);
 
 num = 10;
 msg1 = reshape(img, 1000, 10);
 
 %% Scrambling the image
 scrambler = comm.Scrambler(16,'1 + z^-2 + z^-3 + z^-5 + z^-7',[0 3 2 2 5 1 7]);
 for i=1:10
     msg(:,i)=scrambler(msg1(:,i));
 end
 
 dataMod = qammod(msg,16);
 %%
H = comm.RaisedCosineTransmitFilter('RolloffFactor',0.6,'OutputSamplesPerSymbol',sps,'FilterSpanInSymbols',10);
%%
while 1
%% transmit image
for i = 1 : num
    seg = dataMod(:,i);
    msg_add = qammod(i,16);
    if i == num
        eof = 1+1i;
    else
        eof = 1-1i;
    end
    tag = [ msg_type; msg_add; eof];
    frame = [Header; tag; seg; eof];
    data = H(frame);
    null = zeros(floor(length(data)/20),1);
    tx([data; null]/10);
    pause(0.2)
end

%% transmit text
% msg = 'Hello world through underwater magnetic induction wireless communication!';
% msg_dec = double(msg);
% m_msg_bits = de2bi(msg_dec);
% v_msg_bits = reshape(m_msg_bits',1,[]);
% v_frame_bits = randi([0,1],1,4*1000);
% v_frame_bits(1:length(v_msg_bits))=v_msg_bits;
% v_symbol_payload = qammod(v_frame_bits',16,'InputType','bit');
% symbol_type = qammod(1,16);
% msg_length = length(msg);
% msg_length_bits = de2bi(msg_length,8);
% symbol_msg_length = qammod(msg_length_bits',16,'InputType','bit');
% v_frame_symbol = [Header;symbol_type;symbol_msg_length;v_symbol_payload];
% 
% data = H(v_frame_symbol);
% null = zeros(floor(length(data)/10),1);
% tx([data; null]/10);
% 
%  pause(1);
end
    