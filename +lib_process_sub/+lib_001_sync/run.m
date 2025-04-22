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

    persistent coarse_peak_vec;
    persistent fine_peak_vec;
    persistent fine_peak_sto_fractional_vec;
    persistent sto_fractional_vec;

    persistent cnt;

    if isempty(scale)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        scale = lib_extract.scale_fac(packet_struct);
        samp_rate = lib_extract.samp_rate_hw(packet_struct);

        n_elem = run_call.n_processing * run_call.n_packets_per_json;

        coarse_peak_vec = zeros(1, n_elem);
        fine_peak_vec = zeros(1, n_elem);
        fine_peak_sto_fractional_vec = zeros(1, n_elem);
        sto_fractional_vec = zeros(1, n_elem);

        cnt = 1;
    end

    %% run processing for a series of consecutive files

    % extract first structure
    json_with_meta = json_with_meta_vec{1};

    % extract rms of every packet
    for i=1:numel(json_with_meta.packet_cells)
        % extract one packet
        packet_struct = json_with_meta.packet_cells{i};

        coarse_peak_vec(cnt) = packet_struct.PHY.sync_report.coarse_peak_time;
        fine_peak_vec(cnt) = lib_extract.fine_peak(packet_struct);
        fine_peak_sto_fractional_vec(cnt) = packet_struct.PHY.sync_report.fine_peak_time_corrected_by_sto_fractional;
        sto_fractional_vec(cnt) = packet_struct.PHY.sync_report.sto_fractional;

        cnt = cnt + 1;
    end


    %% is this the final call?
    if run_call.n_processing == run_call.i
        %% subsampling values
        figure(100)
        clf()

        t = fine_peak_vec / samp_rate;

        %% coarse vs fine peak
        subplot(2,1,1)

        plot(t, fine_peak_vec - coarse_peak_vec);

        title('+lib_001_sync', 'Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('Deviation in Samples');

        legend('fine_peak_vec - coarse_peak_vec', 'Interpreter', 'none');

        grid on
        grid minor

        ylim([-2.5 2.5]);

        %% fractional STO
        subplot(2,1,2)

        plot(t, sto_fractional_vec);
        hold on
        plot(t, fine_peak_vec - fine_peak_sto_fractional_vec);

        title('+lib_001_sync', 'Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('Deviation in Samples');

        legend('sto_fractional_vec', 'fine_peak_vec - fine_peak_sto_fractional_vec', 'Interpreter', 'none');

        grid on
        grid minor

        ylim([-2.5 2.5]);
    end
end