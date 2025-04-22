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

function [] = run(json_with_meta_vec, run_call)

    global plot_debug_allow;

    %% acts as a state machine

    persistent scale;
    persistent samp_rate;

    persistent snr_vec;
    persistent mcs_vec;
    persistent fine_peak_vec;

    persistent cnt;

    if isempty(scale)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        scale = lib_extract.scale_fac(packet_struct);
        samp_rate = lib_extract.samp_rate_hw(packet_struct);

        n_elem = run_call.n_processing * run_call.n_packets_per_json;

        snr_vec = zeros(1, n_elem);
        mcs_vec = zeros(1, n_elem);

        fine_peak_vec = snr_vec;

        cnt = 1;
    end

    %% run processing for a series of consecutive files

    % extract first structure
    json_with_meta = json_with_meta_vec{1};

    % extract rms of every packet
    for i=1:numel(json_with_meta.packet_cells)
        % extract one packet
        packet_struct = json_with_meta.packet_cells{i};

        snr_vec(cnt) = packet_struct.PHY.rx_synced.snr;
        mcs_vec(cnt) = packet_struct.PHY.rx_synced.mcs;
        fine_peak_vec(cnt) = lib_extract.fine_peak(packet_struct);

        cnt = cnt + 1;
    end


    %% is this the final call?
    if run_call.n_processing == run_call.i
        %% power
        figure(300)
        clf()

        % convert to seconds
        t = fine_peak_vec / samp_rate;

        plot(t, snr_vec);
        grid on
        grid minor
        ylim([-10, 50]);
        xlabel('Time in sec');
        ylabel('SNR dB');

        yyaxis right
        plot(t, mcs_vec);
        ylim([-2, 16]);
        xlabel('Time in sec');
        ylabel('MCS');

        title('+lib_003_snr_mcs', 'Interpreter', 'none');
        xlabel('Time in sec');
    end
end