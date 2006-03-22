function FitWeibull (datafile)

% FitWeibull fits a Weibull function to CrossoverMCS data,
% 
% Fits data from one file output by the CrossoverMCS code, plots the
% observed data and the fitted function, and reports fit parameters
% and the levels of noise needed to obtain certain levels of
% performance.
%
% One argument must be provided, giving the path to the file
% containing data to fit.

% Authors: David E. Fencsik
% $LastChangedDate$

debug = 1;
minObs = 5;

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
response = 1 - dt{colError};
noise = dt{colNoise};
stable = dt{colStable};

Subjects = sort(unique(subject));
Conditions = sort(unique(condition));
SetSizes = sort(unique(setsize));

for sub = Subjects
   for cond = Conditions
      figure;

      % pick only those trials for this subject, condition, and setsize
      filter = strcmp(subject, sub) & strcmp(condition, cond) & prac == 0;
      noise2 = noise(filter);
      NoiseLevels = sort(unique(noise2));
      nNoiseLevels = length(NoiseLevels);

      useNoiseLevels = zeros(size(NoiseLevels));
      for n = 1:nNoiseLevels
         filter2 = (filter & noise == NoiseLevels(n));
         if length(response(filter2 & target)) >= minObs && length(response(filter2 & ~target)) >= minObs
            useNoiseLevels(n) = 1;
         end
      end

      useNoiseLevels = find(useNoiseLevels == 1);
      NoiseLevels = NoiseLevels(useNoiseLevels);
      nNoiseLevels = length(NoiseLevels);

      % initialize vars
      cneg = zeros(nNoiseLevels, 1); cpos = cneg; nneg = cneg; npos = cneg;

      % compute cell counts
      for n = 1:nNoiseLevels
         filter2 = (filter & noise == NoiseLevels(n));
         cpos(n) = sum(response(filter2 & target));
         cneg(n) = sum(response(filter2 & ~target));
         npos(n) = length(response(filter2 & target));
         nneg(n) = length(response(filter2 & ~target));
      end

      % correct cell counts
      index = cpos == 0;    if any(index), cpos(index) = 0.5;               end
      index = cpos == npos; if any(index), cpos(index) = npos(index) - 0.5; end
      index = cneg == 0;    if any(index), cneg(index) = 0.5;               end
      index = cneg == nneg; if any(index), cneg(index) = nneg(index) - 0.5; end

      % compute hit rate
      hr = cpos ./ npos;
      % compute false-alarm rate
      fa = 1 - cneg ./ nneg;

      % compute d'
      dprime = norminv(hr) - norminv(fa);

      if debug > 0
         %        12345678901234567890123456789012345678901234567890123456789
         fprintf('  Noise   #Hits   #TP  HitRate  #TNEG   #TA   FARate    d''\n');
         for n = 1:nNoiseLevels
            fprintf('%7.4f%8.1f%6.0f%8.2f%8.1f%6.0f%8.2f%8.2f\n', ...
                    NoiseLevels(n), ...
                    cpos(n), npos(n), hr(n), ...
                    cneg(n), nneg(n), fa(n), dprime(n));
         end
      end

      % plot observed data
      x = NoiseLevels;
      plot(x, dprime, 'ok');
      hold on;
      axis([0 1 -.5 4.5]);
      title(sprintf('Subject %s - Condition %s', sub{1}, cond{1}));
      xlabel('Percentage noise');
      ylabel('d''');

      % plot 95% confidence intervals
      ci = Compute95CI(cpos, cneg, npos, nneg);
      for n = 1:nNoiseLevels
         plot([x(n) x(n)], ci(n, :), '-k');
      end

      % fit weibull
      GoodnessOfFit = @(p) sum((dprime - weibull(x, p)) .^ 2); % create an anonymous function
      [p0, gof, exitflag, output] = fminsearch(GoodnessOfFit, [3, .5, 4]);
      if exitflag ~= 1
         fprintf('FMINSEARCH quit after %d iterations and %d function evaluations.\n\n', ...
                 output.iterations, output.funcCount);
      end

      % plot fitted weibull
      x0 = 0:.01:1;
      y0 = weibull(x0, p0);
      plot(x0, y0, 'k', 'LineWidth', 2);

      % output fit information:
      dprime0 = weibull(x, p0);
      fprintf('Subject %s - Condition %s\n', sub{1}, cond{1})
      fprintf('Fitted Weibull\n');
      fprintf('Parameters: threshold = %0.2f, slope = %0.2f, asymptote = %0.2f\n', p0);
      fprintf('Goodness-of-fit: R^2 = %0.4f\n', corr2(dprime, dprime0) ^ 2);

      % print and plot levels of noise corresponding to certain values of d-prime
      ys = [1.0, 1.5, 2.0, 2.5];
      colors = ['r', 'g', 'b', 'm', 'c'];
      for n = 1:length(ys);
         y = ys(n);
         x = weibullinv(y, p0);
         fprintf('Noise level of %0.6f leads to d'' = %3.2f\n', x, y);
         miny = min(get(gca, 'Ylim'));
         plot([0 x], [y y], colors(n), 'LineWidth', 2);
         plot([x x], [miny y], colors(n), 'LineWidth', 2);
      end

      hold off;
   end
end


% Define Weibull function, with an extra parameter that specifies an
% asymptote, and an inverse Weibull
%
% parameters: (1) threshold/scale, (2) slope/shape, (3) asymptote
function y = weibull (x, param)
% y = param(3) + (param(4) - param(3)) * (1 - exp(((x - 1) ./ param(1)) .^ param(2)));
y = param(3) * wblcdf(1 - x, param(1), param(2));

function x = weibullinv (y, param)
x = 1 - param(1) * (-1 * log( (param(3) - y) ./ param(3))) .^ (1 / param(2));
if any(y < 0 | y > param(3))
   x(y < 0 | y > param(3)) = NaN;
end


function ci = Compute95CI (cpos, cneg, npos, nneg)
hr = cpos ./ npos;
fa = 1 - cneg ./ nneg;
phiHR = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(hr));
phiFA = 1 ./ sqrt(2*pi) .* exp(-.5 .* norminv(fa));
dprime = norminv(hr) - norminv(fa);
delta = 1.96 * sqrt( hr .* (1-hr) ./ npos ./ (phiHR.^2) + fa .* (1-fa) ./ nneg ./ (phiFA.^2));
ci = [dprime - delta, dprime + delta];
