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

function [] = preprocess(config_preprocess)

    filenames = config_preprocess.filenames;
    n_files = numel(filenames);

    %% determine how many triplets we can preprocess

    N_FILES_REQUIRED = 3;

    assert(n_files >= N_FILES_REQUIRED, 'At least %d json-files required to preprocess. However, number of files is %d. You probably have to wait for the SDR to generate enough files.', N_FILES_REQUIRED, n_files);

    % how often can we provide the required number of consecutive JSONs?
    n_preprocessing = n_files-(N_FILES_REQUIRED-1);

    assert(n_preprocessing > 0);

    fprintf("Preprocessing: \tIncluding %d files. Will generate %d preprocessed files.\n", n_files, n_files);
    fprintf("Preprocessing: \tFirst file = %s\n", getfield(filenames, {1}, 'name'));
    fprintf("Preprocessing: \tLast file = %s\n", getfield(filenames, {numel(filenames)}, 'name'));

    %% create or clear target folder for preprocessed files

    if exist(config_preprocess.folder_preprocessed', 'dir')
        lib_util.clear_directory(config_preprocess.folder_preprocessed);
    else
        mkdir(config_preprocess.folder_preprocessed);
    end

    %% very important sanity check: are the times from file to file increasing?

    % for sanity checks of packet sizes and times
    n_packets_in_center_third = zeros(1, n_preprocessing);
    first_time_in_center_third = zeros(1, n_preprocessing);
    last_time_in_center_third = zeros(1, n_preprocessing);

    %% multithreading
    parfor_arg = 0;
    if config_preprocess.multithreaded
        parfor_arg = Inf;
    end

    %% process measurement files in triplets
    parfor (i = 1:n_preprocessing, parfor_arg)
    
        % determine names of three consecutive JSON files
        json_name_A = fullfile(getfield(filenames, {i}, 'folder'), getfield(filenames, {i}, 'name'));
        json_name_B = fullfile(getfield(filenames, {i+1}, 'folder'), getfield(filenames, {i+1}, 'name'));
        json_name_C = fullfile(getfield(filenames, {i+2}, 'folder'), getfield(filenames, {i+2}, 'name'));

        assert(~strcmp(json_name_A, json_name_B), 'must be different files');
        assert(~strcmp(json_name_A, json_name_C), 'must be different files');
        assert(~strcmp(json_name_B, json_name_C), 'must be different files');
        
        % load three consecutive JSON files
        json_A = lib_preprocess.json_load_and_parse(json_name_A);
        json_B = lib_preprocess.json_load_and_parse(json_name_B);
        json_C = lib_preprocess.json_load_and_parse(json_name_C);

        % merge all JSON files into one large file, but do not sort just yet
        json_merged = lib_preprocess.json_triplet_merge(json_A, json_B, json_C);

        % get center third
        json_with_meta = lib_preprocess.json_triplet_sort_and_get_specific_third(json_merged, 1);

        % save for later assert
        n_packets_in_center_third(i) = numel(json_with_meta.packet_names);
        first_time_in_center_third(i) = json_with_meta.packet_times(1);
        last_time_in_center_third(i) = json_with_meta.packet_times(end);

        % save file
        lib_preprocess.json_preprocessed_save_to_file(config_preprocess.folder_preprocessed, json_with_meta, i);

        % first call?
        if i == 1
            % then get first third
            json_with_meta = lib_preprocess.json_triplet_sort_and_get_specific_third(json_merged, 0);

            A = numel(json_with_meta.packet_names);
            B = json_with_meta.packet_times(end);

            assert(A == n_packets_in_center_third(i), "not the same number of packets");
            assert(B < first_time_in_center_third(i), "times out of order");

            % save file
            lib_preprocess.json_preprocessed_save_to_file(config_preprocess.folder_preprocessed, json_with_meta, 0);
        end

        % last call?
        if i == n_preprocessing
            % then save last third
            json_with_meta = lib_preprocess.json_triplet_sort_and_get_specific_third(json_merged, 2);

            A = numel(json_with_meta.packet_names);
            B = json_with_meta.packet_times(1);

            assert(A == n_packets_in_center_third(i), "not the same number of packets");
            assert(last_time_in_center_third(i) < B, "times out of order");

            % save file
            lib_preprocess.json_preprocessed_save_to_file(config_preprocess.folder_preprocessed, json_with_meta, i+1);
        end

        fprintf("Preprocessing: \tTriplet with index %d of %d finished.\n", i, n_preprocessing);
    end

    % run sanity checks on packet sizes
    assert(isscalar(unique(n_packets_in_center_third)), "must contains the same number of packets");
    
    % run sanity checks on center third
    assert(lib_util.is_strictly_increasing(first_time_in_center_third), "not strictly increasing");
    assert(lib_util.is_strictly_increasing(last_time_in_center_third), "not strictly increasing");

    % interleave first and last time
    A = zeros(1, 2*numel(last_time_in_center_third));
    A(1:2:end) = first_time_in_center_third;
    A(2:2:end) = last_time_in_center_third;

    assert(lib_util.is_strictly_increasing(A), "not strictly increasing");
end
