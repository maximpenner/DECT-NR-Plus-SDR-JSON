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

function [] = run_001(json_with_meta_vec, run_call)

    global plot_debug_allow;

    %% acts as a state machine

    persistent scale;

    persistent N_b_DFT;
    persistent N_b_OCC_plus_DC;

    persistent samp_rate_dect;

    persistent n_guards_upper;
    persistent n_guards_lower;

    persistent tau;

    persistent impulse_response_norm_abs_sum;

    persistent plot_debug_allowed_local;

    if isempty(scale)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        scale = lib_extract.scale_fac(packet_struct);

        [N_b_DFT, N_b_OCC_plus_DC] = lib_extract.DFT_lengths(packet_struct);

        [u, b] = lib_extract.mu_beta(packet_struct);

        samp_rate_dect = u*b*1.728e6;

        n_guards_upper = (N_b_DFT - N_b_OCC_plus_DC-1) / 2;
        n_guards_lower = n_guards_upper + 1;

        assert(n_guards_upper + N_b_OCC_plus_DC + n_guards_lower == N_b_DFT);

        tau = (0:1:(N_b_DFT-1))' * 1/samp_rate_dect;      

        impulse_response_norm_abs_sum = zeros(N_b_DFT, 1);

        plot_debug_allowed_local = true;

        if ~plot_debug_allow
            plot_debug_allowed_local = false;
        end
    end

    %% run processing for a series of consecutive files

    if plot_debug_allowed_local
        figure(10000)
        clf()
    end

    % first json
    json_with_meta = json_with_meta_vec{1};

    n_packets = numel(json_with_meta.packet_names);

    for i=1:n_packets

        % get specific packet
        packet_struct = json_with_meta.packet_cells{i};

        % extract frequency response
        [ch_estim, stride] = lib_extract.ch_estimation(packet_struct);
        assert(stride == 1, "stride must be 1");

        % add virtual guards
        assert(numel(ch_estim) == N_b_OCC_plus_DC, "incorrect length");

        % make sure all packets have the same configuration
        [N_b_DFT_, N_b_OCC_plus_DC_] = lib_extract.DFT_lengths(packet_struct);
        assert(N_b_DFT == N_b_DFT_);
        assert(N_b_OCC_plus_DC == N_b_OCC_plus_DC_);

        % normalize power of ch_estim
        ch_estim_guards = [zeros(n_guards_lower, 1); ch_estim; zeros(n_guards_upper, 1)];
        ch_estim_guards_norm = ch_estim_guards / rms(ch_estim_guards);

        % convert to time domain
        impulse_response_guards_norm = ifft(fftshift(ch_estim_guards_norm));
        impulse_response_guards_norm_abs = abs(impulse_response_guards_norm);
        impulse_response_guards_norm_abs_dB = mag2db(impulse_response_guards_norm_abs);

        % sum power
        impulse_response_norm_abs_sum = impulse_response_norm_abs_sum + impulse_response_guards_norm_abs;

        if plot_debug_allowed_local
            % f_axis of the same length
            f_axis = -N_b_DFT/2:1:(N_b_DFT/2-1);

            % f-domain magnitude
            ch_estim_guards_abs = abs(ch_estim_guards);
            ch_estim_guards_abs_dB = mag2db(ch_estim_guards_abs);
            subplot(3,1,1)
            plot(f_axis, ch_estim_guards_abs_dB);
            hold on

            % f-domain phase
            ch_estim_guards_angle = angle(ch_estim_guards);
            subplot(3,1,2)
            plot(f_axis, ch_estim_guards_angle);
            hold on
            
            % t-domain
            subplot(3,1,3)
            plot(tau, impulse_response_guards_norm_abs_dB);
            hold on
        end
    end

    if plot_debug_allowed_local
        subplot(3,1,1)
        
        ylim([-40 10]);
        grid on
        grid minor
        
        title('+lib_001_delay_spread', 'Interpreter', 'none');
        ylabel("Abs dB");
        xlabel("Subcarrier Index");

        subplot(3,1,2)

        ylim([-2*pi 2*pi]);
        grid on
        grid minor
        
        title('+lib_001_delay_spread', 'Interpreter', 'none');
        ylabel("Angle Rad");
        xlabel("Subcarrier Index");
        
        subplot(3,1,3)
        
        xline(100e-9);
        xline(1e-6);
        
        xlim([-10e-9 10e-6]);
        ylim([-120 10]);
        grid on
        grid minor
        
        title('+lib_001_delay_spread', 'Interpreter', 'none');
        ylabel("Abs dB");
        xlabel("Time in Seconds");
    end

    %% is this the final call?
    if run_call.n_processing == run_call.i
        % average power
        impulse_response_norm_abs_sum_avg = impulse_response_norm_abs_sum / (run_call.n_processing * run_call.n_packets_per_json);

        % only consider a fraction at the beginning
        N = round(numel(impulse_response_norm_abs_sum_avg)*0.5);
        impulse_response_norm_abs_sum_avg = impulse_response_norm_abs_sum_avg(1:N);

        % convert to dB
        impulse_response_norm_abs_sum_avg_dB = mag2db(impulse_response_norm_abs_sum_avg);

        % normalize
        impulse_response_norm_abs_sum_avg_dB = impulse_response_norm_abs_sum_avg_dB - impulse_response_norm_abs_sum_avg_dB(1);

        % define different noise floor that we want to assume
        noise_floor_dB_vec = [100, -20, -30, -40, -50];

        % preallocate corresponding tau_rms
        tau_rms_vec = zeros(size(noise_floor_dB_vec));

        % calculate for each potential noise floor
        for i=1:numel(noise_floor_dB_vec)
            
            % find the first values below a threshold
            idx_noise_floor = find(impulse_response_norm_abs_sum_avg_dB >= noise_floor_dB_vec(i), 1, 'last');

            if isempty(idx_noise_floor)
                idx_noise_floor = 1;
            end
    
            % finally calculate tau tms
            [tau_rms_vec(i), ~] = get_tau_rms(tau(1:idx_noise_floor), impulse_response_norm_abs_sum_avg(1:idx_noise_floor));
        end

        %% start plotting
        figure(100)
        clf()
        
        %% delay spread magnitude linear
        subplot(2,1,1)
        plot(tau(1:N), db2mag(impulse_response_norm_abs_sum_avg_dB));

        xline(1e-6);
        xline(tau_rms_vec, '--');
        
        xlim([-10e-9 2e-6]);
        ylim([-0.5 2]);
        grid on
        grid minor

        % scientific notation
        ax = gca;
        ax.XAxis.Exponent = -6;
        
        title('+lib_001_delay_spread', 'Interpreter', 'none');
        ylabel("Abs");
        xlabel("tau in sec");

        %% delay spread magnitude dB
        subplot(2,1,2)
        plot(tau(1:N), impulse_response_norm_abs_sum_avg_dB);
        
        xline(1e-6);
        xline(tau_rms_vec, '--');
        
        xlim([-10e-9 2e-6]);
        ylim([-120 10]);
        grid on
        grid minor

        yline(noise_floor_dB_vec, 'r')

        legend('delay spread', 'Vertical Line at 1us', 'Vertical Line at tau_rms', 'Interpreter', 'none');

        % scientific notation
        ax = gca;
        ax.XAxis.Exponent = -6;
        
        title('+lib_001_delay_spread', 'Interpreter', 'none');
        ylabel("Abs dB");
        xlabel("tau in sec");

        %% show table in Figure
        figure(101);
        clf();

        % in nanoseconds
        tau_rms_vec_ns = tau_rms_vec / 1e-9;

        % columns
        noise_floor_dB_vec = noise_floor_dB_vec';
        tau_rms_vec_ns = tau_rms_vec_ns';

        lib_view.plot_table(table(noise_floor_dB_vec, tau_rms_vec_ns));
    end
end

function [tau_rms, tau_mean] = get_tau_rms(t_axis, impulse_response_abs_sum_avg)
    % source: https://en.wikipedia.org/wiki/Delay_spread

    A = impulse_response_abs_sum_avg.^2;

    tau_mean = sum(t_axis.*A) / sum(A);

    tau_rms = sum((t_axis - tau_mean).^2 .* A) / sum(A);
    tau_rms = sqrt(tau_rms);
end