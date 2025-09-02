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

function [] = clear_directory(directory_path)

    % first find all recorded files
    [filenames, n_files] = lib_file_collection.get_all_filenames(directory_path);

    % delete all files
    for i=1:1:n_files
        full_filepath = fullfile(filenames(i).folder,filenames(i).name);
        delete(full_filepath);
    end
end