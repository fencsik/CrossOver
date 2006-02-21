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

if nargin < 1 || isempty(datafile)
   error('data filename missing');
end

fid = fopen(datafile, 'r');
if fid == -1, error(sprintf('Cannot open file %s for reading', datafile)); end

%%% load header information
format = ['%s', repmat(' %s', 1, 24)];
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
colSetSize = find(strcmp(header, 'ss'));
colTarget = find(strcmp(header, 'TP?'));
colError = find(strcmp(header, 'err'));
colNoise = find(strcmp(header, 'noiseParam'));

%%% load the remaining data
format = '%s %s %d %s %s %s %s %d %d %f %d %d %d %d %f %s %d %d %d %d %s %s %d %d %f';
dt = textscan(fid, format, 10000, 'delimiter', '\t');
fclose(fid);

subject = dt{colSubject};
condition = dt{colCondition};
setsize = dt{colSetSize};
target = dt{colTarget};
response = 1 - dt{colError};
noise = dt{colNoise};

Subjects = sort(unique(subject));
Conditions = sort(unique(condition));
SetSizes = sort(unique(setsize));

for sub = Subjects
   for cond = Conditions
      for ss = SetSizes
         filter = (strcmp(subject, sub) & strcmp(condition, cond) & setsize == ss);
         noise2 = noise(filter);
         NoiseLevels = sort(unique(noise2));
         nNoiseLevels = length(NoiseLevels);
         hr = zeros(nNoiseLevels, 1);
         fa = hr;
         cneg = hr;
         cpos = hr;
         nneg = hr;
         npos = hr;
         for n = 1:nNoiseLevels
            filter2 = (filter & noise == NoiseLevels(n));
            cpos(n) = sum(response(filter2 & target));
            cneg(n) = sum(response(filter2 & ~target));
            npos(n) = sum(filter2 & target);
            nneg(n) = sum(filter2 & ~target);
         end
         % compute hit rate
         hr = cpos ./ npos;
         % compute false-alarm rate
         fa = 1 - cneg ./ nneg;
         %%% fprintf('Before correction:\n'); disp([NoiseLevels, cpos, npos, hr, cneg, nneg, fa]);
         % correct any HR or FA that are 0 or 1
         index = hr == 0; if any(index), hr(index) = 1 ./ (2 * npos(index)); end
         index = hr == 1; if any(index), hr(index) = 1 - 1 ./ (2 * npos(index)); end
         index = fa == 0; if any(index), fa(index) = 1 ./ (2 * nneg(index)); end
         index = fa == 1; if any(index), fa(index) = 1 - 1 ./ (2 * nneg(index)); end
         % compute d'
         dprime = norminv(hr) - norminv(fa);
         
         %%% fprintf('After correction:\n'); disp([NoiseLevels, cpos, npos, hr, cneg, nneg, fa, dprime]);

         x = NoiseLevels;
         plot(x, dprime, 'ok');
         hold on;
         axis([0 1 -.5 4.5]);
         title(sprintf('Subject %s - Condition %s - Set Size %d', sub{1}, cond{1}, ss));
         xlabel('Percentage noise');
         ylabel('d''');
         
         % fit weibull
         GoodnessOfFit = @(p) sum((dprime - weibull(x, p)) .^ 2); % create an anonymous function
         [p0, gof, exitflag, output] = fminsearch(GoodnessOfFit, [3, .5, 0, 4]);
         if exitflag ~= 1
            fprintf('FMINSEARCH quit after %d iterations and %d function evaluations.\n\n', ...
                    output.iterations, output.funcCount);
         end
         x0 = 0:.01:1;
         y0 = weibull(x0, p0);
         plot(x0, y0, 'k', 'LineWidth', 2);

         % output fit:
         dprime0 = weibull(x, p0);
         fprintf('Subject %s - Condition %s - Set Size %d\n', sub{1}, cond{1}, ss)
         fprintf('Fitted Weibull\n');
         fprintf('Parameters: threshold = %0.2f, slope = %0.2f, bounds = [%0.2f, %0.2f]\n', ...
                 p0);
         fprintf('Goodness-of-fit: R^2 = %0.4f\n', corr2(x, dprime0) ^ 2);

         ys = [0.5, 1.0, 1.5];
         colors = ['r', 'g', 'b'];
         for n = 1:length(ys);
            y = ys(n);
            x = weibullinv(y, p0);
            fprintf('Noise level of %0.4f leads to d'' = %3.1f\n', x, y);
            plot([0 x], [y y], colors(n));
            plot([x x], [-2 y], colors(n));
         end

         hold off;
      end
   end
end


%% weibull parameters: (1) threshold/scale, (2) slope/shape, (3) baseline, (4) asymptote
function y = weibull (x, param)
y = param(3) + (param(4) - param(3)) * wblcdf(1 - x, param(1), param(2));

function x = weibullinv (y, param)
x = 1 - param(1) * (-1 * log( (param(4) - y) ./ (param(4) - param(3)))) .^ (1 / param(2));
