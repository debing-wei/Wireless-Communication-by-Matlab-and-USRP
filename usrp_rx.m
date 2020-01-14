%% system perameters
samples_per_symbol = 20;
payload_length = 1000+26+3;    % symbols per fram
sample_length = samples_per_symbol*payload_length;    % samples per fram
% sample_length = sample_length+10*samples_per_symbol;
frame_length = round(sample_length*1.02);
% signal_threadhold = 1500;
% noise_power = 500;
signal_threadhold = 0.005;
noise_power = 0.001;

number_frams_burst = 7;
m_raw_data = zeros(sample_length,number_frams_burst);

v_flag_image_frame = zeros(10,1);
m_frame_image = zeros(1000,10);

count = 0;
image = 0;


%% initicialize usrp
% rx = comm.SDRuReceiver('Platform','X310');
% rx.CenterFrequency = 120e3;
% rx.MasterClockRate = 120e6;
% rx.DecimationFactor = 500;
% rx.SamplesPerFrame = sample_length; % = 223*80
% rx.EnableBurstMode = true;
% rx.NumFramesInBurst = number_frams_burst;


%% reading data from usrp

v_tmp_data = zeros(2*sample_length,1);
m_frame = zeros(frame_length,number_frams_burst);
v_frame_valid = zeros(number_frams_burst,1);

len = uint32(0);
h = rcosdesign(0.6,10,samples_per_symbol);   % match filter
descrambler = comm.Descrambler(16,[1 0 1 1 0 1 0 1],[0 3 2 2 5 1 7]);

while 1        
    
    v_frame_valid = zeros(number_frams_burst,1);

    % reading data
    for i=1:number_frams_burst           
       [m_raw_data(:,i), len] = rx();  
       if len == 0
           disp('reading error');
       end
    end

    m_data_sps20 = m_raw_data;
    v_data_sps20 = reshape(m_data_sps20,[],1);
    v_data_matchfilter = upfirdn(v_data_sps20,h)*2/16384;
    group_delay = samples_per_symbol*10/2;
    v_data_matchfilter = v_data_matchfilter(group_delay+1:number_frams_burst*sample_length+group_delay);
    m_data_matchfilter = reshape(v_data_matchfilter,sample_length,number_frams_burst);

    % valid frame detection
    %------------------------
    m_data_sps2 = downsample(m_data_matchfilter,10);
    v_sample_power = var(m_data_sps2);
    v_flag_data_valid = v_sample_power > noise_power;
   
    
    if sum(v_flag_data_valid)>0
        if abs(v_data_matchfilter(1))+abs(v_data_matchfilter(10)) > signal_threadhold
            v_first_frame = abs(m_data_sps2(:,1));
            frame_length_sps2 = length(v_first_frame);
            v_first_frame(1:frame_length_sps2-1) = v_first_frame(1:frame_length_sps2-1)+v_first_frame(2:end);
            index_last_sample = find(v_first_frame < signal_threadhold,1);
            zero_length = (index_last_sample + 2)*samples_per_symbol/2;
            m_data_matchfilter(1:zero_length,1) = zeros(zero_length,1);
            v_flag_data_valid(1) = var(m_data_matchfilter(:,1)) > noise_power;
        end
    end

   
    if sum(v_flag_data_valid)>0
%         data_location = find(v_flag_data_valid==1);
        flag_previous_frame = 0;        
        
       for i = 1:number_frams_burst
            if flag_previous_frame
                flag_previous_frame = 0;
                v_tmp_data(sample_length+1:end) = m_data_matchfilter(:,i);
                [m_frame(:,i),LSB,MSB] = myframeDetec(v_tmp_data,signal_threadhold,frame_length,i);
                v_frame_valid(i)=1;
                v_tmp_data(LSB+1:MSB) = 0;
                power_temp_data = max(v_tmp_data(sample_length+1:end));
                if abs(power_temp_data)>signal_threadhold
                    v_tmp_data(1:sample_length) = v_tmp_data(sample_length+1:end);
                    flag_previous_frame = 1;
                end
            elseif v_flag_data_valid(i)
                flag_previous_frame = 1;
                v_tmp_data(1:sample_length) = m_data_matchfilter(:,i);
            end
        end         
    end
    
    % demodulation 
    %--------------------------
    if sum(v_frame_valid)>0
        for i=2:number_frams_burst 
            if v_frame_valid(i)                
               v_frame_ready = preDemod(m_frame(:,i),samples_per_symbol,payload_length); 
               v_frame_valid(i) = 0; 
               frame_type = qamdemod(v_frame_ready(1),16);
               switch frame_type
                   case 1  % text
                       text_character_length = bi2de([qamdemod(v_frame_ready(2),16,'OutputType','bit'); qamdemod(v_frame_ready(3),16,'OutputType','bit')]');
                       text_bit_length = text_character_length * 7;
                       text_symbol_length = ceil(text_bit_length/4);
                       v_text_bit = qamdemod(v_frame_ready(4:text_symbol_length+4),16,'OutputType','bit');
                       m_text_bit = reshape(v_text_bit(1:7*text_character_length),7,text_character_length)';
                       v_text_dec = bi2de(m_text_bit);
                       v_text_string = char(v_text_dec)';
                       disp(v_text_string);
                       image = 1;
                       pause(1);
                       break;
                       
                   case 2  % picture
                       count = count + 1;
                           if count > 50
                               close all
                               count = 0;
%                                break;
                           end
                       imag_frame_index = qamdemod(v_frame_ready(2),16);
                       if imag_frame_index <=10 && imag_frame_index > 0
                           % updata image frames 
                           disp('picture is not ready')
                           
                           if v_flag_image_frame(imag_frame_index)== 0
                               v_flag_image_frame(imag_frame_index) = 1;
                               m_frame_image(:,imag_frame_index) = qamdemod(v_frame_ready(4:end),16); 
                               m_frame_image(:,imag_frame_index) = descrambler(m_frame_image(:,imag_frame_index));
                           end
                           % image receiving completed ?
                           if sum(v_flag_image_frame)==10
                               close all;
                               v_flag_image_frame = zeros(10,1);
                               img = reshape(m_frame_image,100,100);
                               imshow(uint8(img*16));
                               % BER
                                 img_original =rgb2gray(imread('shasta' ,'jpg'));
                                 img_original = imresize(img_original,[100 100]);
                                 img_original = floor(img_original/16-1);
                                 img_original = de2bi(reshape(img_original,[],1));
                                 img_received = de2bi(reshape(img,[],1));
                                 [numerr, BER]= biterr(img_original,img_received);
                                 
                               pause(1);
                               image = 1;
                               break
                           end
                       else
                           disp('receiving image error !');
                       end
                       
                   otherwise
                       disp('unknown frame received');
               end
            end
        end
        if image
          break;
        end
    end

end

% stop(usrp_burst_timer)
disp('rx finished.')

%%
function [v_frame,LSB,MSB] = myframeDetec(v_data,threadhold,frame_length,frame_index)
 
t = find(abs(v_data)>threadhold);
if isempty(t)
    v_frame = v_data(1:frame_length); 
    LSB = 1;
    MSB = frame_length+1;
    disp(['error one ',num2str(frame_index)])
else
    LSB = max((t(1)-round(frame_length*0.008)),1);
    if LSB > (length(v_data)-frame_length)
        v_frame = v_data(length(v_data)-frame_length+1:end);        
        MSB = length(v_data);
        LSB = length(v_data) - MSB;
        disp(['error two ',num2str(frame_index)])
    else
        MSB = LSB + frame_length;
        disp(['error three ',num2str(LSB)])
        v_frame = v_data(LSB+1:MSB);
    end
end

end

function [v_frame_equalized] = preDemod(v_frame_matchfilter,sps,payload_length)

%% Symbol Syncronization
                
v_frame_sps2=zeros(19,sps);
gradient_data=zeros(18,1);
optimal_point_index=zeros(18,1);
timeing_err=zeros(sps,1);
for i=1:sps
    v_frame_sps2(:, i)=v_frame_matchfilter(i+sps*2:sps:sps*(19+2));
    gradient_data(:,1)=diff(v_frame_sps2(:,i));
    optimal_point_index(:,1)=v_frame_matchfilter(i+sps*2+sps/2:sps:sps*(18+2)+i);
   timeing_err(i,1)=sum(abs(optimal_point_index(:,1).*gradient_data(:,1)));
end
[M,I]=min(timeing_err);

v_frame_sym_syncronized = v_frame_matchfilter(I:sps:end);
% scatterplot(v_frame_sym_syncronized,1,0,'kx');
% title('SS');

%% AGC

v_frame_agc = sqrt(7.5/var(v_frame_sym_syncronized))*v_frame_sym_syncronized;
% scatterplot(v_frame_agc,1,0,'kx');

%% Carrier synchronization

CarrierSyncronize = comm.CarrierSynchronizer( ...
'DampingFactor',0.707*1, ...
'NormalizedLoopBandwidth',0.012/2, ...    
'SamplesPerSymbol',1, ...
'Modulation','QAM');

v_frame_sym_carrier = CarrierSyncronize(v_frame_agc);
% scatterplot(v_frame_sym_carrier,1,0,'kx')
% title('CS');

%% preable detection
prb = [+1 +1 +1 +1 +1 -1 -1 +1 +1 -1 +1 -1 +1]'*(3+3i);
prb = [prb; conj(prb)];
prbdet = comm.PreambleDetector(prb);
prbdet.Threshold = 20;
[idx,detmet] = prbdet(v_frame_sym_carrier);
[~,fl] = max(detmet(26:45));
fl = fl + 25;
%v_rx_fram_sync = carrier_syncronized_signals(fl-25:fl+plength+1); 
% payload_length = 1000+3;
v_frame_sync = v_frame_agc(fl-25:fl+payload_length-26);

%% Equalization
lineq = comm.LinearEqualizer('Algorithm','LMS', ...
    'NumTaps',4, ...
    'ReferenceTap',1, ...
    'Constellation',qammod(0:15,16),...
    'StepSize',0.01*1.2);
  %  ;
lineq.WeightUpdatePeriod = 1;
[v_frame_equalized1,err,weight] = lineq(v_frame_sync,prb);
% stem(abs(weight));
v_frame_equalized = v_frame_equalized1(27:end);
  scatterplot(v_frame_equalized,1,0,'kx')
 title('EQ');
end

