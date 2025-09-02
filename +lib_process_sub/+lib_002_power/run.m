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

function [] = run(json_with_meta_vec, run_call)

    global plot_debug_allow;

    %% acts as a state machine

    persistent scale;
    persistent samp_rate;

    persistent tx_power_ant_0dBFS_vec;
    persistent rx_power_ant_0dBFS_vec;

    persistent detection_ant_idx_vec;
    persistent detection_metric_vec;

    persistent rms_vec_vec;

    persistent fine_peak_vec;

    persistent cnt;

    if isempty(scale)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        scale = lib_extract.scale_fac(packet_struct);
        samp_rate = lib_extract.samp_rate_hw(packet_struct);

        n_elem = run_call.n_processing * run_call.n_packets_per_json;

        tx_power_ant_0dBFS_vec = zeros(1, n_elem);
        rx_power_ant_0dBFS_vec = zeros(8, n_elem);

        detection_ant_idx_vec = tx_power_ant_0dBFS_vec;
        detection_metric_vec = tx_power_ant_0dBFS_vec;

        rms_vec_vec = zeros(8, n_elem);

        fine_peak_vec = tx_power_ant_0dBFS_vec;

        cnt = 1;
    end

    %% run processing for a series of consecutive files

    % extract first structure
    json_with_meta = json_with_meta_vec{1};

    % extract rms of every packet
    for i=1:numel(json_with_meta.packet_cells)
        % extract one packet
        packet_struct = json_with_meta.packet_cells{i};

        tx_power_ant_0dBFS_vec(:, cnt) = packet_struct.RADIO.tx_power_ant_0dBFS;
        rx_power_ant_0dBFS_vec(:, cnt) = packet_struct.RADIO.rx_power_ant_0dBFS;

        detection_ant_idx_vec(cnt) = packet_struct.PHY.sync_report.detection_ant_idx;
        detection_metric_vec(cnt) = packet_struct.PHY.sync_report.detection_metric;

        rms_vec_vec(:, cnt) = packet_struct.PHY.sync_report.rms_array;

        fine_peak_vec(cnt) = lib_extract.fine_peak(packet_struct);

        cnt = cnt + 1;
    end


    %% is this the final call?
    if run_call.n_processing == run_call.i
        %% power at 0dBFS
        figure(200)
        clf()

        % convert to seconds
        t = fine_peak_vec / samp_rate;
        
        plot(t, tx_power_ant_0dBFS_vec, '--');
        hold on
        plot(t, rx_power_ant_0dBFS_vec);

        title('+lib_002_power', 'Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('dBm');

        legend('Interpreter', 'none');

        tmp = gca;
        tmp.Legend.String(1) = {"TX"};
        for i=2:1:9
            tmp.Legend.String(i) = {"RX" + num2str(i-2)};
        end

        grid on
        grid minor

        ylim([-120, 70]);

        %% rms
        figure(201)
        clf()

        plot(t, rms_vec_vec);

        title('+lib_002_power', 'Interpreter', 'none');
        legend('Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('rms_vec_vec', 'Interpreter', 'none');

        tmp = gca;
        for i=1:1:8
            tmp.Legend.String(i) = {"RX" + num2str(i-1)};
        end

        grid on
        grid minor

        ylim([-0.1, 0.75]);

        %% power
        figure(202)
        clf()

        power_dBm = rx_power_ant_0dBFS_vec + mag2db(rms_vec_vec);
        power_lin = db2pow(power_dBm);

        power_avg_dBm = pow2db(mean(power_lin, 'all'));

        power_max_dBm = pow2db(sum(power_lin, 1));

        plot(t, power_dBm);
        hold on
        yline(power_avg_dBm)
        plot(t, power_max_dBm, '--', 'LineWidth', 2)

        title('+lib_002_power', 'Interpreter', 'none');
        legend('Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('dBm', 'Interpreter', 'none');

        tmp = gca;
        for i=1:1:8
            tmp.Legend.String(i) = {"RX" + num2str(i-1)};
        end
        tmp.Legend.String(9) = {"avg"};
        tmp.Legend.String(10) = {"sum"};

        grid on
        grid minor

        ylim([-120, 10]);

        %% antenna of detection
        figure(203)
        clf()

        subplot(2,1,1);
        plot(t, detection_ant_idx_vec);

        title('+lib_002_power', 'Interpreter', 'none');
        
        xlabel('Time in sec');
        ylabel('detection_ant_idx_vec', 'Interpreter', 'none');

        ylim([-1 9]);
        grid on
        grid minor

        subplot(2,1,2);
        plot(t, detection_metric_vec);

        title('+lib_002_power', 'Interpreter', 'none');
        
        xlabel('Time is sec', 'Interpreter', 'none');
        ylabel('detection_metric_vec', 'Interpreter', 'none');

        ylim([-0.1 2.0]);
        grid on
        grid minor
    end
end