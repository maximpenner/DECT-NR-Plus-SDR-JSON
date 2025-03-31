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

function [] = process(config_process)

    assert(exist(config_process.folder_preprocessed, 'dir'), 'no folder');
    assert(config_process.n_consecutive > 0, 'must be positive');

    %% load all files in folder
    
    [filenames, n_files] = lib_file_collection.get_all_filenames(config_process.folder_preprocessed);
    
    assert(numel(filenames) == n_files);
    assert(n_files >= config_process.n_consecutive, 'Preprocessing must provide at least %d files to processing. Number of files is %d.', config_process.n_consecutive, n_files);

    %% determine how many times we can process

    n_processing = n_files-(config_process.n_consecutive-1);

    fprintf("\n");
    fprintf("Processing: \tIncluding %d files. Will process %d times as %d consecutive file(s) is(are) required.\n", n_files, n_processing, config_process.n_consecutive);
    fprintf("Processing: \tFirst file = %s\n", getfield(filenames, {1}, 'name'));
    fprintf("Processing: \tLast file = %s\n", getfield(filenames, {numel(filenames)}, 'name'));

    %% process files
    for i=1:n_processing

        % names of consecutive files
        filepaths_consecutive = cell(config_process.n_consecutive,1);
        for j=0:(config_process.n_consecutive-1)
            filepaths_consecutive{1+j} = fullfile(getfield(filenames, {i+j}, 'folder'), getfield(filenames, {i+j}, 'name'));
        end

        % load consecutive files
        json_with_meta_vec = lib_process.json_consecutive_read(filepaths_consecutive);

        % indicate number of calls of process sub functions
        run_call.n_processing = n_processing;
        run_call.i = i;
        run_call.n_packets_per_json = numel(json_with_meta_vec{1}.packet_names);

        % actual processing of neighbouring files
        lib_process_sub.lib_001_delay_spread.run_001(json_with_meta_vec, run_call);
        lib_process_sub.lib_002_power.run_002(json_with_meta_vec, run_call);
        lib_process_sub.lib_003_snr.run_003(json_with_meta_vec, run_call);
        lib_process_sub.lib_004_per.run_004(json_with_meta_vec, run_call);
        %lib_process_sub.lib_005_doppler.run_005(json_with_meta_vec, run_call);
        lib_process_sub.lib_006_subsampling.run_006(json_with_meta_vec, run_call);

        fprintf("Processing: \tProgress %.2f %%. Call %d of %d finished.\n", i/n_processing*100, i, n_processing);
    end
end