
for j = -500:10:500
    X = [];
    for i = 1:length(locs)
        [~,pilot_t] = ofdmdemod(rxsig(locs(i)+j:locs(i)+j+6000-1));
        X = [X pilot_t];
    end
    hist(abs(X(1,:)));pause(0.5);
end