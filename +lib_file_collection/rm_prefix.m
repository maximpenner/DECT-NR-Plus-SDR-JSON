%
% Copyright 2024-2025 Maxim Penner
%
% This file is part of DECTNRP.
%
% DECTNRP is free software: you can redistribute it and/or modify
% it under the terms of the GNU Affero General Public License as
% published by the Free Software Foundation, either version 3 of
% the License, or (at your option) any later version.
%
% DECTNRP is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
% GNU Affero General Public License for more details.
% A copy of the GNU Affero General Public License can be found in
% the LICENSE file in the top-level directory of this distribution
% and at http://www.gnu.org/licenses/.

function [filenames] = rm_prefix(filenames, prefix)

    n_files = numel(filenames);

    n_prefix = numel(prefix);

    for i=n_files:-1:1

        fn = getfield(filenames, {i}, 'name');

        if numel(fn) < n_prefix
            filenames(i) = [];
            continue;
        end

        if ~strcmp(fn(1:n_prefix), prefix)
            filenames(i) = [];
            continue;
        end
    end
end