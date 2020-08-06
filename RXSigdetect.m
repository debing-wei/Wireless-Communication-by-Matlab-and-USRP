USRPrxSetup;
%% collect data
hlog = dsp.SignalSink;release(rx);
while 1
    rxsig = double(real(rx()));
    rxsig = filloutliers(rxsig,'linear');
    t = [1:length(rxsig)]/fs;
    threshold = 200;
    if var(rxsig)<threshold
        disp('no signal!');
        data = hlog.Buffer;
        if not(isempty(data))
           hlog(rxsig);data = hlog.Buffer;release(hlog);release(rx);break;
        end
    else
        N = 1000; L = 5000; len = length(rxsig);
        ch = rxsig;
        timesync;
%         subplot(2,1,1);
        plot(t,rxsig);
%         subplot(2,1,2);
%         plot(M);
        hlog(rxsig);
    end
end