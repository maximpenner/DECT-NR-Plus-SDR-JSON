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

function [json_some_third] = json_triplet_sort_and_get_specific_third(json_merged, index_of_third_to_extract)
    
    %% sort all fields by the fine sync point

    order = json_merged.packet_times_sorted_indices;
    
    json_some_third.packet_names                = json_merged.packet_names(order);
    json_some_third.packet_cells                = json_merged.packet_cells(order);
    json_some_third.packet_indices              = json_merged.packet_indices(order);
    json_some_third.packet_times                = json_merged.packet_times(order);
    json_some_third.packet_times_sorted_indices = json_merged.packet_times_sorted_indices(order);

    times_diff = json_some_third.packet_times(2:end) - json_some_third.packet_times(1:end-1);
    assert(min(times_diff) > 0);

    %% save specific third

    N = numel(json_some_third.packet_names);

    assert(N > 0, "must be at least one packet");
    assert(mod(N, 3) == 0, "not a multiple of three");
    assert(0 <= index_of_third_to_extract, "out of bound");
    assert(index_of_third_to_extract <= 2, "out of bound");

    A = 1 + index_of_third_to_extract * N / 3;
    B = A + N / 3 - 1;

    json_some_third.packet_names                = json_some_third.packet_names(A:B);
    json_some_third.packet_cells                = json_some_third.packet_cells(A:B);
    json_some_third.packet_indices              = json_some_third.packet_indices(A:B);
    json_some_third.packet_times                = json_some_third.packet_times(A:B);
    json_some_third.packet_times_sorted_indices = json_some_third.packet_times_sorted_indices(A:B);
end