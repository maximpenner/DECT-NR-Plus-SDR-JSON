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

function [] = run_005(json_with_meta_vec, run_call)
    global plot_debug_allow;

    %% acts as a state machine

    persistent scale;

    persistent N_b_DFT;
    persistent N_b_OCC_plus_DC;

    persistent samp_rate_converted;

    persistent n_guards_upper;
    persistent n_guards_lower;

    persistent ch_estim_array_cell;
    persistent packet_count;
    persistent time_vec;
    persistent time_vec_reference;
    
    persistent impulse_respone_length_idx;
    
    % over how many packets do we want to correlate in the time domain
    correlation_time_nof_packets = 500;
    
    % what is the packet rate (default is 1 every 10 ms)
    packet_rate_per_second = 100;

    % set packet rate to be calculated by the elapsed time in the JSON
    calculate_packet_rate = false;

    if isempty(scale)
        % extract first packet to read values that never change
        json_with_meta = json_with_meta_vec{1};
        packet_struct = json_with_meta.packet_cells{1};

        scale = lib_extract.scale_fac(packet_struct);

        [N_b_DFT, N_b_OCC_plus_DC] = lib_extract.DFT_lengths(packet_struct);

        samp_rate_converted = lib_extract.samp_rate_hw(packet_struct) * N_b_OCC_plus_DC / N_b_DFT;

        n_guards_upper = (N_b_DFT - N_b_OCC_plus_DC-1) / 2;
        n_guards_lower = n_guards_upper + 1;

        assert(n_guards_upper + N_b_OCC_plus_DC + n_guards_lower == N_b_DFT);

        tau_converted = (0:1:(N_b_OCC_plus_DC-1))' * 1/samp_rate_converted;

        assert(numel(tau_converted) == N_b_OCC_plus_DC);

        plot_debug_allowed_local = true;

        n_packets = numel(json_with_meta.packet_names);

        ch_estim_array_cell = cell(0);
        packet_count = 0;
        time_vec_reference = packet_struct.elapsed_since_epoch;

        if ~plot_debug_allow
            plot_debug_allowed_local = false;
        end
    end

    % first json
    json_with_meta = json_with_meta_vec{1};

    n_packets = numel(json_with_meta.packet_names);

    % over how many packets do we want to correlate in time?
    %n_corr = n_packets;
    
    %n_corr_idx = ceil(n_packets/n_corr);

    for i=1:1:n_packets

            packet_count = packet_count+1;
            
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
            ch_estim_norm = ch_estim/rms(ch_estim);
            ch_estim_array_cell{packet_count} = ch_estim_norm;

            time_vec(packet_count) = (packet_struct.elapsed_since_epoch - time_vec_reference)*(10^-9);

            impulse_response_norm = ifft(fftshift(ch_estim_norm));
            impulse_response_norm_abs = abs(impulse_response_norm);
            impulse_response_norm_abs_dB = mag2db(impulse_response_norm_abs);
            
            % normalize
            impulse_response_norm_abs_dB = impulse_response_norm_abs_dB - impulse_response_norm_abs_dB(1);
            
            % cut off the cyclic part
            impulse_response_norm_abs_dB(end-floor(numel(impulse_response_norm_abs_dB)*0.1):end) = [];
            
            % find the last index above the defined noise floor
            noise_floor_dB = -40;
            impulse_respone_length_idx(packet_count) = find((impulse_response_norm_abs_dB>noise_floor_dB),1,"last");
    end

    %% is this the final call?
    if run_call.n_processing == run_call.i

        if packet_count>correlation_time_nof_packets

            [possible_constant_packet_rate_idx] = check_time_is_valid(time_vec, correlation_time_nof_packets);

            Doppler_rms_vec = numel(possible_constant_packet_rate_idx);
            Doppler_mean_vec = numel(possible_constant_packet_rate_idx);
            time_vec_figure = numel(possible_constant_packet_rate_idx);
            
            if isequal(numel(possible_constant_packet_rate_idx),0)
                warning("packet rate not constant enough. Decrease %correlation_time_nof_packets% or use more JSON Files")
            end

            Doppler_frequencies = [];
            Doppler_spectral_density_norm_dB = [];
            Doppler_rms = [];

            for i=1:numel(possible_constant_packet_rate_idx)

                % select only the packets with the possible constant packet
                % rate
                valid_packets_vec = possible_constant_packet_rate_idx(i):possible_constant_packet_rate_idx(i)+correlation_time_nof_packets-1;

                time_vec_valid = time_vec(valid_packets_vec);

                ch_estim_array_cell_valid = cell(1,correlation_time_nof_packets);
                for j=1:correlation_time_nof_packets
                    ch_estim_array_cell_valid{j} = ch_estim_array_cell{valid_packets_vec(j)};
                end

                % convert cell to array
                ch_estim_array = zeros(N_b_OCC_plus_DC, size(ch_estim_array_cell_valid,2));
                for j=1:size(ch_estim_array,2)
                    ch_estim_array(:,j) = ch_estim_array_cell_valid{j};
                end
    
                % average impulse response length
                avg_impulse_response_length_idx = floor(mean(impulse_respone_length_idx(valid_packets_vec)));
    
                % calculate impulse response matrix
                impulse_response_array = ifft(fftshift(ch_estim_array,1),size(ch_estim_array,1),1);
    
                % cut off behind the average length
                impulse_response_array(avg_impulse_response_length_idx+1:end,:) = [];
                %impulse_response_array = impulse_response_array(1,:);

                % calculate Doppler-variant impulse response
                Doppler_impulse_response = fft(impulse_response_array, size(impulse_response_array,2),2);
    
                % The Scattering function is defined as the Power of the
                % Doppler-variant impulse response
                scattering_function = abs(fftshift(Doppler_impulse_response)).^2;
    
                % calculate the Doppler Density by using the integral
                Doppler_spectral_density = sum(scattering_function,1);
                Doppler_spectral_density_norm = Doppler_spectral_density./max(Doppler_spectral_density);
                Doppler_spectral_density_norm_dB  = db(Doppler_spectral_density_norm,"power");
                size_Doppler_density = numel(Doppler_spectral_density_norm_dB);
    
                % average sampling time for arriving packets (has to be
                % scheduled)
                samp_time_arriving_packets = mean(diff(time_vec_valid));

                if isequal(calculate_packet_rate, true)
                    samp_rate_arriving_packets = 1/samp_time_arriving_packets;
                else
                    samp_rate_arriving_packets = packet_rate_per_second;
                end
    
                % calculate doppler frequency axis
                Doppler_frequencies = (-size_Doppler_density/2:1:(size_Doppler_density/2)-1)' * (samp_rate_arriving_packets/size_Doppler_density);
                %Doppler_frequencies = Doppler_frequencies/max(Doppler_frequencies)*25;    

                % calculate Doppler rms
                [Doppler_rms, Doppler_mean] = get_Doppler_rms(Doppler_frequencies, Doppler_spectral_density_norm);

                Doppler_rms_vec(i) = Doppler_rms;
                Doppler_mean_vec(i) = Doppler_mean;
                time_vec_figure(i) = time_vec_valid(end);
            end

            figure(500);
            subplot(2,1,1);
            plot(Doppler_frequencies, Doppler_spectral_density_norm_dB);
            grid on;
            title('+lib_005_doppler', 'Interpreter', 'none');
            ylabel("Doppler spectral density");
            xlabel("Doppler frequency in Hz");
            ylim([-50 10]);
            
            delete(findall(gcf,'type','annotation'))

            dim = [.55 .6 .25 .25];
            str = strcat('Doppler mean = ', num2str(Doppler_mean), ' Hz');
            annotation('textbox',dim,'String',str,'FitBoxToText','on', 'Interpreter', 'none');

            subplot(2,1,2);
            plot(time_vec_figure,Doppler_rms_vec);
            grid on;
            title('+lib_005_doppler', 'Interpreter', 'none');
            ylabel("RMS Doppler spread")
            xlabel("time")
            ylim([min(Doppler_frequencies) max(Doppler_frequencies)])
            
        else
            warning("not enough packets to correlate in time");
        end
    end
end

function [Doppler_rms, Doppler_mean] = get_Doppler_rms(Doppler_frequencies, Doppler_density)
    % set threshhold
    doppler_spec_dens_cut_off_threshhold = -10;

    Doppler_density_dB = db(Doppler_density,"power");

    Doppler_spec_dens_cut_off = Doppler_density;
    Doppler_freq_cut_off = Doppler_frequencies;

    Doppler_spec_dens_cut_off_idx = Doppler_density_dB > doppler_spec_dens_cut_off_threshhold;

    Doppler_spec_dens_cut_off(find(Doppler_spec_dens_cut_off_idx, 1, 'last' )+1:numel(Doppler_density_dB)) = [];
    Doppler_freq_cut_off(find(Doppler_spec_dens_cut_off_idx, 1, 'last' )+1:numel(Doppler_density_dB)) = [];
    Doppler_spec_dens_cut_off(1:find(Doppler_spec_dens_cut_off_idx, 1, 'first')-1) = [];
    Doppler_freq_cut_off(1:find(Doppler_spec_dens_cut_off_idx, 1, 'first')-1) = [];

    Doppler_spec_dens_cut_off = Doppler_spec_dens_cut_off.';

    Doppler_mean = sum(Doppler_freq_cut_off.*Doppler_spec_dens_cut_off)/sum(Doppler_spec_dens_cut_off);
    Doppler_rms = sqrt(sum(((Doppler_freq_cut_off-Doppler_mean).^2).*Doppler_spec_dens_cut_off)/sum(Doppler_spec_dens_cut_off));
end

function [time_vec_valid_idx] = check_time_is_valid(time_vector, correlation_time_nof_packets)
    % returns index on which a number of %%correlation_time_nof_packets%% packets with constant packet rate follow

    diff_time_vec = diff(time_vector);
    correlation_time_nof_packets_diff = correlation_time_nof_packets-1;

    time_vec_valid_idx = [];
    
    i=1;
    while (i+correlation_time_nof_packets-1)<=numel(diff_time_vec)
        [S,M] = std(diff_time_vec(i:i+correlation_time_nof_packets_diff-1));
        if S<M*0.1
            time_vec_valid_idx = [time_vec_valid_idx, i];
            i = i+correlation_time_nof_packets_diff;
        else
            i=i+1;
        end
    end
end
