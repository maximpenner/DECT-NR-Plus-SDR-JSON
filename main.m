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

%close all;

while 1
    clear all;
    clc;
    
    % Each library in +lib_process_sub extracts a specific information from the measured data.
    % Each library always plot results at the end of processing, but can also plot during processing for
    % debugging purposes. With this variable, we can globally allow these plots.
    global plot_debug_allow;
    plot_debug_allow = false;
    
    % file collection
    config_file_collection.folder_measurements = 'json_examples/';
    %config_file_collection.folder_measurements = '../bin/';
    config_file_collection.prefix = 'worker_pool_';
    config_file_collection.n_end_ignore = 0;
    config_file_collection.n_end_keep = 0;
    config_file_collection.n_start_ignore = 0;
    config_file_collection.n_start_keep = 0;
    
    [filenames, filenames_all] = lib_file_collection.file_collection(config_file_collection);
    
    % preprocessing
    config_preprocess.filenames = filenames;
    config_preprocess.folder_preprocessed = 'json_preprocessed/';
    config_preprocess.multithreaded = false;
    
    lib_preprocess.preprocess(config_preprocess);
    
    % processing
    config_process.folder_preprocessed = config_preprocess.folder_preprocessed;
    config_process.n_consecutive = 1;
    
    lib_process.process(config_process);
    
    % give figures some time to update
    pause(1);

    % focus specific figures
    lib_view.focus([]);

    % single run if processing all files
    if config_file_collection.n_end_keep == 0
        fprintf('\nAll files analyzed. Exiting.\n');
        return;
    end

    fprintf('\nRequire new files to process. Checking now.\n');

    % load all files available now
    [~, filenames_all_now] = lib_file_collection.file_collection(config_file_collection);

    while numel(filenames_all_now) <= numel(filenames_all)
        disp('No new files available yet. Waiting to check again ...');

        % give SDR some time to generate a new JSON
        pause(5);

        % update files
        [~, filenames_all_now] = lib_file_collection.file_collection(config_file_collection);
    end
end