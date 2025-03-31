#
# Copyright 2023-2025 Maxim Penner
#
# This file is part of DECTNRP.
#
# DECTNRP is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# DECTNRP is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU Affero General Public License for more details.
#
# A copy of the GNU Affero General Public License can be found in
# the LICENSE file in the top-level directory of this distribution
# and at http://www.gnu.org/licenses/.

from lib_extract import extract_scalar
from lib_read import read_filename, read_json

def main():

    print("function main")

    # folder with json files
    directory = "/path/to/folder/"

    # read all file names
    filenames = read_filename.read_all_filenames(directory)

    # read each json file
    json = read_json.read_json(filenames)

    # read values from all files
    samp_rate = extract_scalar.extract_sample_rate(json)

if __name__ == '__main__':
    main()