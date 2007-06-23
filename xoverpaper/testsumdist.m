function testsumdist

% testsumdist tests a formulation for the distributions underlying the
% sum-rule model for search tasks.
%
% Plotting works only for unlimited-capacity versions of the rule
% (i.e., k >= setsize), but predicted HR and FA should be correct.
%
% $LastChangedDate$

% adjustable settings
dprime = 3.0;
criterion = 2.5;
setsize = 10;
ntrials = 100000;
k = 100;

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
% sum first k stimuli (or the first n if k >= n [n = setsize])
k = min([k, setsize]);
sumval = sum(values(:, 1:k), 2);
response = sumval > criterion;
fa = sum(response(target == 0)) / ntrials;
hr = sum(response(target == 1)) / ntrials;

[yn, xn] = hist(sumval(target == 0), 100);
[yt, xt] = hist(sumval(target == 1), 100);
yn = yn / sum(yn);
yt = yt / sum(yt);
plot(xn, yn, 'color', [1 0 0], 'linewidth', 3); hold on;
plot(xt, yt, 'color', [0 1 0], 'linewidth', 3);

yn = normpdf(xn, 0, sqrt(k));
yt = normpdf(xt, dprime, sqrt(k));
yn = yn / sum(yn);
yt = yt / sum(yt);
plot(xn, yn, 'color', [.5 0 0], 'linewidth', 2);
plot(xt, yt, 'color', [0 .5 0], 'linewidth', 2);
axis([-12 15 0 .05]);
hold off;

n = setsize;
c = criterion;
k = min([k, n]);
predFA = 1 - normcdf(c, 0, sqrt(k));
predHR = k / n * (1 - normcdf(c, dprime, sqrt(k))) + (n - k) / n * (1 - normcdf(c, 0, sqrt(k)));

disp([predHR, hr]);
disp([predFA, fa]);

% [d, c] = maxdprime(hr, fa, setsize, k),
