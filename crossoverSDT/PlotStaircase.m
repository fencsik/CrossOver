function PlotStaircase (datafile)

% PlotStaircase plots noise as a function of trial
% 
% One argument must be provided, giving the path to the file
% containing data to plot.

% Authors: David E. Fencsik
% $LastChangedDate$

axislimits = [0.5 10.5 0 4];

if nargin < 1 || isempty(datafile)
   error('data filename missing');
end

fid = fopen(datafile, 'r');
if fid == -1, error(sprintf('Cannot open file %s for reading', datafile)); end

%%% load header information
format = ['%s', repmat(' %s', 1, 27)];
header2 = textscan(fid, format, 1, 'delimiter', '\t');
header = cell(1, length(header2));
for n = 1:length(header2)
   header{n} = header2{n}{1};
end

% for n = 1:length(header)
%    fprintf('header{%d} = %s\n', n, header{n});
% end

%%% which columns go with certain variables
colSubject = find(strcmp(header, 'sinit'));
colCondition = find(strcmp(header, 'cond'));
colPractice = find(strcmp(header, 'pr/exp'));
colTrial = find(strcmp(header, 'ctr'));
colSetSize = find(strcmp(header, 'ss'));
colTarget = find(strcmp(header, 'TP?'));
colError = find(strcmp(header, 'err'));
colNoise = find(strcmp(header, 'noiseParam'));
colStable = find(strcmp(header, 'Stable?'));

%%% load the remaining data
format = '%s %s %d %s %s %s %s %d %d %f %d %d %d %d %f %s %d %d %d %d %s %s %d %d %f %s %d %d';
dt = textscan(fid, format, 10000, 'delimiter', '\t');
fclose(fid);

subject = dt{colSubject};
condition = dt{colCondition};
trial = dt{colTrial};
setsize = dt{colSetSize};
target = dt{colTarget};
prac = strcmp(dt{colPractice}, 'practice');
correct = 1 - dt{colError};
noise = dt{colNoise};
stable = dt{colStable};

AllConditions = sort(unique(condition));
AllNoiseLevels = sort(unique(noise));
AllSetSizes = sort(unique(setsize));

% dprime = nan(length(AllSetSizes), length(AllNoiseLevels));

Subjects = sort(unique(subject));
for nsub = 1:length(Subjects)
   sub = Subjects{nsub};
   % filter out all other subjects
   filterSub = strcmp(subject, sub) & prac == 0;
   % figure out which condition this subject ran in
   Conditions = sort(unique(condition(filterSub)));

   figure;
   colors = 'bgrcmyk';
   points = 'os^x+d*';
   counter = 1;

   for ncond = 1:length(Conditions)
      cond = Conditions{ncond};
      % filter out all other conditions and subjects
      filterSubCond = filterSub & strcmp(condition, cond);
      % figure out which set sizes were run for this condition and subject

      x = trial(filterSubCond);
      y = noise(filterSubCond);

      plot(x, y, 'LineWidth', 1, 'MarkerSize', 4, 'MarkerFaceColor', 'w');

      hold on;

      text(double(x(length(x))) * 1.01, double(y(length(y))), cond, 'Color', colors(counter));
      axis([1, max(x) * 1.1, 0, 1]);
      title(sprintf('Subject %s', sub));
      xlabel('Trial');
      ylabel('Proportion noise');

      counter = counter + 1;
   end % loop over conditions
   % plot(axislimits(1:2), [2 2], 'k--');
   hold off;

end % loop over subjects



% function to compute dprimes and 95%-confidence intervals around them
function [dprime, ci, hr, fa] = ComputeDprime (cpos, cneg, npos, nneg)
hr = cpos ./ npos;
fa = 1 - cneg ./ nneg;
phiHR = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(hr));
phiFA = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(fa));
dprime = norminv(hr) - norminv(fa);
ci = 1.96 * sqrt( hr .* (1-hr) ./ npos ./ (phiHR.^2) + fa .* (1-fa) ./ nneg ./ (phiFA.^2));
