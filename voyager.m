
%% VOYAGER DEEP-SPACE COMMUNICATION - DSP SIMULATION
% MATLAB implementation matching the Simulink block diagram
% Simulation only - no hardware required

clc;
clear;
close all;

fprintf('============================================\n');
fprintf(' VOYAGER DEEP-SPACE DSP SIMULATION\n');
fprintf('============================================\n\n');

%% 1. TRANSMITTED SIGNAL - SINE WAVE

Fs = 1000;                  % Sampling frequency (Hz)
Ts = 1/Fs;                  % Sampling interval (s)
duration = 2;               % Simulation duration (s)

t = 0:Ts:duration-Ts;

amplitude = 1;
frequency = 20;             % Sine-wave frequency (Hz)

tx = amplitude*sin(2*pi*frequency*t);

fprintf('1. TRANSMITTED SIGNAL GENERATED\n');
fprintf('Sampling frequency: %d Hz\n', Fs);
fprintf('Sine-wave frequency: %d Hz\n', frequency);
fprintf('Duration: %.2f seconds\n\n', duration);

%% 2. PROPAGATION DELAY - 150 SAMPLES

delaySamples = 150;
actualDelay = delaySamples/Fs;

delayedSignal = [zeros(1,delaySamples), ...
                 tx(1:end-delaySamples)];

fprintf('2. PROPAGATION DELAY\n');
fprintf('Delay samples: %d\n', delaySamples);
fprintf('Delay time: %.3f seconds\n\n', actualDelay);

%% 3. ATTENUATION - GAIN BLOCK

gain = 0.35;

attenuatedSignal = gain*delayedSignal;

fprintf('3. ATTENUATION\n');
fprintf('Gain: %.2f\n\n', gain);

%% 4. ADD BAND-LIMITED-STYLE NOISE

% Reproducible noise for this code-based demonstration.
% This is white Gaussian noise, not an exact reproduction
% of Simulink's Band-Limited White Noise block.

rng(23341);
noiseStd = 0.15;
noise = noiseStd*randn(size(tx));

receivedSignal = attenuatedSignal + noise;

fprintf('4. NOISE ADDITION\n');
fprintf('Noise standard deviation: %.2f\n\n', noiseStd);

%% 5. DESIGN AND APPLY FIR LOW-PASS FILTER

% Windowed-sinc FIR design using basic MATLAB operations.
% No fir1 or xcorr function is required.

filterOrder = 60;
cutoffHz = 80;

k = -filterOrder/2:filterOrder/2;

h = zeros(size(k));
nonzero = (k ~= 0);

h(nonzero) = sin(2*pi*cutoffHz/Fs*k(nonzero)) ...
             ./ (pi*k(nonzero));

h(~nonzero) = 2*cutoffHz/Fs;

window = 0.54 - 0.46*cos(2*pi*(0:filterOrder)/filterOrder);

h = h.*window;
h = h/sum(h);

filteredSignal = conv(receivedSignal,h,'same');

fprintf('5. FIR FILTERING\n');
fprintf('Filter order: %d\n', filterOrder);
fprintf('Cutoff frequency: %d Hz\n\n', cutoffHz);

%% 6. THREE SIGNAL PLOTS - LIKE SIMULINK SCOPES

figure('Name','Voyager DSP - Three Scope Outputs','Color','w');

subplot(3,1,1);
plot(t,tx,'b','LineWidth',1.2);
title('Scope 1: Transmitted Sine Wave');
xlabel('Time (seconds)');
ylabel('Amplitude');
xlim([0 duration]);
grid on;

subplot(3,1,2);
plot(t,receivedSignal,'Color',[0.75 0.25 0.15]);
title('Scope 2: Received Signal Before Filtering');
xlabel('Time (seconds)');
ylabel('Amplitude');
xlim([0 duration]);
grid on;

subplot(3,1,3);
plot(t,filteredSignal,'Color',[0 0.5 0],'LineWidth',1.2);
title('Scope 3: Received Signal After FIR Low-Pass Filtering');
xlabel('Time (seconds)');
ylabel('Amplitude');
xlim([0 duration]);
grid on;

%% 7. CROSS-CORRELATION FOR DELAY ESTIMATION

% Remove DC offsets before correlation.
reference = tx - mean(tx);
received = receivedSignal - mean(receivedSignal);

% Full correlation, calculated without xcorr.
correlation = conv(received,fliplr(reference));
lags = (1:length(correlation)) - length(reference);

% Restrict the search to nonnegative delays up to 0.4 seconds.
maxDelaySamples = min(round(0.4*Fs),length(tx)-1);
valid = (lags >= 0) & (lags <= maxDelaySamples);

validIndices = find(valid);
[~,localPeak] = max(abs(correlation(valid)));
peakIndex = validIndices(localPeak);

estimatedDelaySamples = lags(peakIndex);
estimatedDelay = estimatedDelaySamples/Fs;

delayErrorSamples = abs(estimatedDelaySamples-delaySamples);

fprintf('6. DELAY ESTIMATION\n');
fprintf('Actual delay: %d samples (%.3f s)\n', ...
        delaySamples,actualDelay);
fprintf('Estimated delay: %d samples (%.3f s)\n', ...
        estimatedDelaySamples,estimatedDelay);
fprintf('Absolute sample error: %d samples\n\n', ...
        delayErrorSamples);

figure('Name','Voyager DSP - Cross-Correlation','Color','w');

plot(lags/Fs,correlation,'b','LineWidth',1.1);
hold on;
xline(actualDelay,'--k','Actual delay');
xline(estimatedDelay,'--r','Estimated delay');

xlabel('Lag (seconds)');
ylabel('Correlation');
title('Cross-Correlation for Propagation Delay Estimation');
xlim([0 maxDelaySamples/Fs]);
grid on;
legend('Cross-correlation','Actual delay', ...
       'Estimated delay','Location','best');
hold off;

%% 8. ILLUSTRATIVE ONE-WAY DISTANCE

speedOfLight = 3e8;

estimatedDistanceKm = speedOfLight*estimatedDelay/1000;
nominalDistanceKm = speedOfLight*actualDelay/1000;

fprintf('7. ILLUSTRATIVE DISTANCE\n');
fprintf('Distance from estimated delay: %.2f km\n', ...
        estimatedDistanceKm);
fprintf('Distance from nominal delay: %.2f km\n', ...
        nominalDistanceKm);
fprintf(['Note: These are illustrative simulation values, ' ...
         'not Voyager actual distance.\n\n']);

%% 9. FFT COMPARISON - BEFORE AND AFTER FILTERING

Yreceived = abs(fft(receivedSignal))/length(receivedSignal);
Yfiltered = abs(fft(filteredSignal))/length(filteredSignal);

numBins = floor(length(tx)/2)+1;
f = (0:numBins-1)*Fs/length(tx);

Yreceived = Yreceived(1:numBins);
Yfiltered = Yfiltered(1:numBins);

if rem(length(tx),2)==0
    Yreceived(2:end-1) = 2*Yreceived(2:end-1);
    Yfiltered(2:end-1) = 2*Yfiltered(2:end-1);
else
    Yreceived(2:end) = 2*Yreceived(2:end);
    Yfiltered(2:end) = 2*Yfiltered(2:end);
end

figure('Name','Voyager DSP - FFT Comparison','Color','w');

plot(f,Yreceived,'r','LineWidth',1);
hold on;
plot(f,Yfiltered,'b','LineWidth',1.2);

title('Frequency Spectrum Before and After FIR Filtering');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0 Fs/2]);
grid on;
legend('Received signal','Filtered signal','Location','best');
hold off;

%% 10. FINAL SUMMARY

fprintf('============================================\n');
fprintf(' SIMULATION COMPLETED\n');
fprintf('============================================\n');
fprintf('Generated transmitted, received and filtered plots.\n');
fprintf('Generated cross-correlation and FFT plots.\n');
fprintf('Check the estimated delay against 150 samples.\n');
