function [dprime, criterion] = sumdprime (hr, fa, n, k)

% sumdprime calculates d' and criterion for a search task assuming
% that response is based on the sum of target and distractor signals
% (i.e., a "sum-rule" model).
%
% [dprime, criterion] = sumdprime(HitRate, FalseAlarmRate, SetSize)
% computes d' and criterion based on the given hit rate, false alarm
% rate, and set size, assuming an unlimited-capacity sum-rule model.
%
% [...] = sumdprime(HitRate, FalseAlarmRate, SetSize, Capacity) is the
% same, but assumes a limited capacity model.  Results will differ
% from the previous version only if Capacity < SetSize.
%
% Each argument must be a scalar value or a vector or matrix with
% matching dimensions.  If both output arguments are omitted, then d'
% and criterion will be printed on the command window.

% Author: David Fencsik <fencsik@gmail.com>
% $LastChangedDate$

%%% ERROR CHECKING AND ARGUMENT CLEANUP %%%

% Check input arguments
if nargin < 3
   error('at least three arguments are required');
end
if nargin < 4
   k = n; 
end

% ensure n and k are scalar or have matching dimensions
if numel(n) > 1 && numel(k) > 1 && any(size(n) ~= size(k))
   error(['SetSize and Capacity arguments must have the same dimensions, '...
          'or at least one must be scalar']);
end

%%% END OF ERROR CHECKING %%%

% set each k to minimum of k and n
k = min(n, k);
% compute criterion
%c = Finv((1 - fa) .^ (1 ./ k));
c = Finv(1 - fa, k);
% compute d'
%d = c - Finv(n .* (1 - hr) ./ k ./ (F(c) .^ (k - 1)) - (n - k) ./ k .* F(c));
d = c - Finv((1 - n ./ k) .* F(c, k) + n ./ k .* (1 - hr), k);

if nargout == 0
   % if no output arguments, then just print the results
   fprintf('d'' = \n'); disp(d);
   fprintf('criterion = \n'); disp(c);
elseif nargout == 1
   dprime = d;
elseif nargout >= 2
   dprime = d;
   criterion = c;
end


function p = F(x, k)
p = normcdf(x, 0, sqrt(k));


function x = Finv(p, k)
x = norminv(p, 0, sqrt(k));
