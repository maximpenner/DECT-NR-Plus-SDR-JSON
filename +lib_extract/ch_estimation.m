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

function [ch_estim, stride] = ch_estimation(packet_struct)

    scale = lib_extract.scale_fac(packet_struct);

    re = packet_struct.PHY.rx_synced.ch_0_0.re / scale;
    im = packet_struct.PHY.rx_synced.ch_0_0.im / scale;

    ch_estim = re + 1i *im;

    stride = packet_struct.PHY.rx_synced.stride;
end