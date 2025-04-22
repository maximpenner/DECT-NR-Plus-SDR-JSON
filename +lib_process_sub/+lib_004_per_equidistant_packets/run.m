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

    persistent samp_rate;

    persistent fine_peak_vec;

    persistent cnt;

    if isempty(samp_rate)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        samp_rate = lib_extract.samp_rate_hw(packet_struct);

        n_elem = run_call.n_processing * run_call.n_packets_per_json;

        snr_vec = zeros(1, n_elem);

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

        fine_peak_vec(cnt) = lib_extract.fine_peak(packet_struct);

        cnt = cnt + 1;
    end

    %% is this the final call?
    if run_call.n_processing == run_call.i
        %% make sure packet times are strictly increasing

        n_samples_packet2packet = fine_peak_vec(2:end) - fine_peak_vec(1:end-1);

        assert(min(n_samples_packet2packet) > 0, 'packet times not strictly increasing');

        %% calculate PER

        % how many seconds from the first to the last packet?
        time_span_sec = (fine_peak_vec(end) - fine_peak_vec(1)) / samp_rate;

        % how many packet do we expect per second?
        n_packet_per_sec_expected = 100;

        % number of packets it should have been
        n_packet_expected = round(time_span_sec * n_packet_per_sec_expected + 1);

        % number of packets recevied
        n_packet_received = numel(fine_peak_vec);

        % PER over all files
        PER = 1 - n_packet_received / n_packet_expected;

        %% plot normalized packet to packet distances
        figure(400)
        clf()

        % start time of each packet in FPGA time
        t = fine_peak_vec(1:end-1) / samp_rate;

        % expected time from packet to packet
        n_samples_packet2packet_expected = 1/n_packet_per_sec_expected*samp_rate;

        % normalize
        n_samples_packet2packet_norm = n_samples_packet2packet / n_samples_packet2packet_expected;

        plot(t, n_samples_packet2packet_norm);

        legend('n_samples_packet2packet_norm', 'Interpreter', 'none');

        title('+lib_004_per_equidistant_packets', 'Interpreter', 'none');

        xlabel('Time in sec');
        ylabel('Normalized Packet to Packet Distance', 'Interpreter', 'none');

        grid on
        grid minor

        ylim([-10, 10]);

        %% show PER

        lib_view.annotation_box([.15 .5], strcat('time_span = ', num2str(time_span_sec), " sec"));
        lib_view.annotation_box([.15 .4], strcat('n_packet_per_sec_expected = ', num2str(n_packet_per_sec_expected)));
        lib_view.annotation_box([.15 .3], strcat('n_packet_expected = ', num2str(n_packet_expected)));
        lib_view.annotation_box([.55 .3], strcat('n_packet_received = ', num2str(n_packet_received)));
        lib_view.annotation_box([.15 .2], strcat('PER = ', num2str(PER)));
    end
end