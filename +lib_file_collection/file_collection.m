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

function [filenames, filenames_all] = file_collection(config_file_collection)

    assert(exist(config_file_collection.folder_measurements, 'dir'), 'folder %s does not exist', config_file_collection.folder_measurements);

    % load all files in folder

    [filenames, ~] = lib_file_collection.get_all_filenames(config_file_collection.folder_measurements);

    % remove all files that do not start with the correct prefix
    filenames = lib_file_collection.rm_prefix(filenames, config_file_collection.prefix);

    % make a copy
    filenames_all = filenames;

    % keep subset
    filenames = lib_file_collection.ignore_keep_end(filenames, config_file_collection.n_end_ignore, config_file_collection.n_end_keep);
    filenames = lib_file_collection.ignore_keep_start(filenames, config_file_collection.n_start_ignore, config_file_collection.n_start_keep);
end

