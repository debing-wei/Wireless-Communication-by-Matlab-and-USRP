% X = csvread('E:\sora\c1.csv');
% t = X(:,1);ch1 = X(:,2);ch2 = X(:,3);
% ch = ch1;
ch = sig(2928:15920);
N = 1000; L = 5000; len = length(ch);
P=[]; R = [];
for i = 1 : len-N+1-L
    slice1 = ch(i:i+N-1); slice2 = ch(i+L:i+L+N-1);
    tmp_p = sum(abs(slice1-slice2));
    tmp_r = sqrt(var(slice1)*var(slice2));
    P = [P tmp_p]; R = [R tmp_r];
end
Q = max(P) - P;
M = Q.*R;
M = M/max(M);
[pks,locs] = findpeaks(M,'MinPeakDistance',4000,'MinPeakHeight',0.8);
% offset = 