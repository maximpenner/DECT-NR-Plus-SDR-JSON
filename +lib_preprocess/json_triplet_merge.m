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

function [json_merged] = json_triplet_merge(json_A, json_B, json_C)
    %% first concatenate both JSONs

    % original
    json_merged.json_A = json_A;
    json_merged.json_B = json_B;
    json_merged.json_C = json_C;

    % convert each individually
    packet_names_A = fieldnames(json_A);
    packet_names_B = fieldnames(json_B);
    packet_names_C = fieldnames(json_C);
    packet_cells_A = struct2cell(json_A);
    packet_cells_B = struct2cell(json_B);
    packet_cells_C = struct2cell(json_C);

    assert(numel(packet_names_A) == numel(packet_names_B));
    assert(numel(packet_cells_A) == numel(packet_cells_C));
    assert(numel(packet_names_B) == numel(packet_cells_C));

    % merge into one large structure
    json_merged.packet_names = [packet_names_A; packet_names_B; packet_names_C];
    json_merged.packet_cells = [packet_cells_A; packet_cells_B; packet_cells_C];

    assert(numel(json_merged.packet_names) == numel(packet_names_A)*3);
    assert(numel(json_merged.packet_names) == numel(json_merged.packet_cells));

    %% create vector with global packet indices as numbers

    json_merged.packet_indices = zeros(size(json_merged.packet_names));

    % by convention every packet name begins with "packet_"
    for i = 1:numel(json_merged.packet_names)
        str = json_merged.packet_names{i};
        str = str(numel('packet_') + 1 : end);
        json_merged.packet_indices(i) = str2double(str);
    end

    % make sure packets have consecutive packets indices
    packet_index_diff = json_merged.packet_indices(2:end) - json_merged.packet_indices(1:end-1);
    assert(min(packet_index_diff) == 1);
    assert(max(packet_index_diff) == 1);

    %% create vector with packet times
    
    json_merged.packet_times = zeros(size(json_merged.packet_names));

    % reading as double is fine, double has enough precision
    for i = 1:numel(json_merged.packet_indices)
        json_merged.packet_times(i) = json_merged.packet_cells{i}.PHY.sync_report.fine_peak;
    end

    % times are not necessarily sorted, create vector of packet indices sorted by time
    [~, json_merged.packet_times_sorted_indices] = sort(json_merged.packet_times);
end