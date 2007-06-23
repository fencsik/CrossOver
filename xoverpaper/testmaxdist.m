function testmaxdist

% testmaxdist tests a formulation for the distributions underlying the
% max model for search tasks
%
% $LastChangedDate$

% adjustable settings
dprime = 4.0;
criterion = 2.0;
setsize = 8;
ntrials = 100;
k = 5;

% plot settings
ylim = [0, .6];

% initialization
rand('twister', 100 * sum(clock));
randn('state', 100 * sum(clock));

% run Monte Carlo simulation
target = [zeros(ntrials, 1); ones(ntrials, 1)];
values = normrnd(0, 1, [ntrials * 2, setsize]);
values(target == 1, 1) = normrnd(dprime, 1, [sum(target == 1), 1]);
% shuffle values
[dummy, sorter] = sort(rand(size(values)), 2);
for i = 1:size(values, 1)
   values(i, :) = values(i, sorter(i, :));
end
% select max of first k stimuli (or the first n if n < k, n = setsize)
maxval = max(values(:, 1:min([k, setsize])), [], 2);
response = maxval > criterion;
fa = sum(response(target == 0)) / ntrials;
hr = sum(response(target == 1)) / ntrials;

% compute predicted values
n = setsize;
c = criterion;
k = min(k, n);
predFA = 1 - normcdf(c) .^ k;
predHR = 1 - k / n * normcdf(c - dprime) * normcdf(c) .^ (k - 1) - ...
         (n - k) / n * normcdf(c) .^ k;
[d, c] = maxdprime(hr, fa, setsize, k);

fprintf('        Simulated  Estimated\n');
fprintf('d''   %10.3f %10.3f\n', dprime, d);
fprintf('crit %10.3f %10.3f\n', criterion, c);
fprintf('HR   %10.3f %10.3f\n', hr, predHR);
fprintf('FA   %10.3f %10.3f\n', fa, predFA);
