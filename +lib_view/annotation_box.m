%
% Copyright 2024-present Maxim Penner
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

function [] = annotation_box(dim, str)

    assert(numel(dim) == 2)
    assert(size(dim, 2) == 2)

    dim = [dim, zeros(1,2)];

    annotation('textbox',dim,'String',str,'FitBoxToText','on', 'Interpreter', 'none');
end
