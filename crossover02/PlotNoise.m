function PlotNoise (datafile)

% PlotNoise plots the average noise at each set-size for each condition.
% 
% One argument must be provided, giving the path to the file
% containing data to plot.

% Authors: David E. Fencsik
% $LastChangedDate$

axislimits = [0.5 9 0.25 0.75];

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

Subjects = sort(unique(subject));
for nsub = 1:length(Subjects)
   sub = Subjects{nsub};
   % filter out all other subjects
   filterSub = strcmp(subject, sub) & prac == 0 & stable == 1;
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
      SetSizes = sort(unique(setsize(filterSubCond)));
      x = SetSizes;
      
      y = nan(length(SetSizes), 2);
      ci = y;
      n = y;
      
      for s = 1:length(SetSizes)
         % filter out all other setsizes (etc.)
         filter = filterSubCond & setsize == SetSizes(s);
         y(s, 1) = mean(noise(filter & ~target));
         y(s, 2) = mean(noise(filter & target));
         n(s, 1) = length(noise(filter & ~target));
         n(s, 2) = length(noise(filter & target));
         ci(s, 1) = 1.96 * sqrt(var(noise(filter & ~target)) / n(s, 1));
         ci(s, 2) = 1.96 * sqrt(var(noise(filter & target)) / n(s, 2));
      end % loop over setsizes

      fprintf('Cond      SetSize Target Num     Noise    95%%-CI\n');
      for s = 1:length(SetSizes)
         for i = 1:2
            fprintf('%-10s%5.0f%7d%6.0f%11.6f%10.6f\n', cond, SetSizes(s), i - 1, n(s, i), y(s, i), ci(s, i));
         end
      end

      % plot avg noise
      plot(x, y(:, 1), [colors(counter), '--' points(counter)], ...
           'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');
      hold on;
      plot(x, y(:, 2), [colors(counter), '-' points(counter)], ...
           'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');

      % plot 95% confidence intervals
      offset = 0.;
      for s = 1:length(SetSizes)
         for i = 1:2
            plot([x(s) x(s)], [y(s, i) + ci(s, i), y(s, i) - ci(s, i)], [colors(counter), '-']);
         end
      end
      plot(x, y(:, 1), [colors(counter), '--' points(counter)], ...
           'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');
      plot(x, y(:, 2), [colors(counter), '-' points(counter)], ...
           'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'w');
      text(8.25, y(length(SetSizes), 1), sprintf('%s-TA', cond), ...
           'Color', colors(counter));
      text(8.25, y(length(SetSizes), 2), sprintf('%s-TP', cond), ...
           'Color', colors(counter));
      counter = counter + 1;

      axis(axislimits);
      title(sprintf('Subject %s', sub));
      xlabel('Set size');
      ylabel('d''');

   end % loop over conditions
   %plot(axislimits(1:2), [2 2], 'k--');
   hold off;

end % loop over subjects
