function [hr, fa] = sumrule (s, c, n, k)

% sumrule computes search performance under a sum-rule decision model
% 
% Usage:
%   [HR, FA] = sumrule (Sensitivity, Criterion, SetSize, Capacity)
% 
% Sensitivity is the difference between the noise and signal
% distributions for each stimulus (i.e., the single-channel d').
% Criterion is the analogous threshold.  SetSize is a list of one or
% more set sizes (i.e., the number of channels).  Capacity is
% optional, and specifies the number of channels that will be attended
% (selected at random).  If Capacity is greater than the largest
% set-size, then capacity is unlimited, which is the default behavior.
% 
% Sensitivity, Criterion, and Capacity must all be scalar values.
% SetSize can be scalar or vector (but not a matrix).
%
% HR and FA are the hit rate and false-alarm rate, respectively,
% predicted by a sum-rule decision model.  Both HR and FA have the
% same shape as the SetSize argument.

% Author: David Fencsik <fencsik@gmail.com>
% $LastChangedDate$

%%% ERROR CHECKING AND ARGUMENT CLEANUP %%%

if nargin < 3
   error('at least three arguments are required');
end
% make sure n is a vector or scalar
if ~isvector(n)
    error('SetSize must be scalar or vector');
end
% default capacity is unlimited
if nargin < 4
   k = max(n); 
end
% ensure s, c, and k are scalar
if numel(s) > 1 || numel(c) > 1 || numel(k) > 1
   error('Sensitivity, Criterion, and Capacity arguments must be scalar');
end

%%% END OF ERROR CHECKING %%%

% set each k to minimum of k and n
k = min(n, k);

fprintf('min(k, n) = \n');
disp(min(k, n));

% compute false-alarm rate
fa = 1 - F(c, k);
% compute hit rate
hr = k ./ n .* (1 - F(c - s, k)) + (n - k) ./ n .* (1 - F(c, k));

function p = F(x, k)
p = normcdf(x, 0, sqrt(k));
