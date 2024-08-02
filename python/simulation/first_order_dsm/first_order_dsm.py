import numpy as np
from matplotlib import pyplot as plt

SAMPLING_RATE = 48000 # Hz
OVERSAMPLING_RATIO = 256
TONE_FREQUENCY = 1000 # Hz

class DSM_Stage_v2:
    def __init__(self, delay_order=1, feedback_gain=1, forward_gain=1, odd_stage=True):
        self.delay_order = delay_order
        self.feedback_gain = feedback_gain
        self.forward_gain = forward_gain
        self.odd_stage = odd_stage
        self.feedback_temp = np.zeros(self.delay_order)

    def delay():
        return 0
    
    def update(self, input, feedback):
        if self.odd_stage:
            return 0
        else:
            return 1

class DSM_Stage:
    def __init__(self):
        self.feedback_temp = 0
        self.feedback_gain = 1
        self.forward_gain = 1
        self.last_stage = True
        #self.odd_stage = True # Used for multiple stages
    
    def update(self, input, feedback):
        temp = self.feedback_temp
        self.feedback_temp = (input - feedback) * self.forward_gain + self.feedback_temp
        if self.last_stage:
            if temp >= 0:
                return 1
            else:
                return -1
        else:
            return temp

if __name__ == "__main__":
    time_length = 0.01 # s
    time_step = 1 / (SAMPLING_RATE * OVERSAMPLING_RATIO)
    sample_count = time_length / time_step
    t = np.arange(0, time_length, time_step)
    x = np.cos(t*2*np.pi*TONE_FREQUENCY)
    y = np.zeros(np.shape(t))
    dsm_stage = DSM_Stage()
    print('Created signals')
    y[0] = dsm_stage.update(input=x[0], feedback=0)
    for i in range(np.size(t)-1):
        y[i+1] = dsm_stage.update(input=x[i+1], feedback=y[i])
    print('Ran DSM modulator')
    F = np.fft.fft(y)
    F = np.abs(F)
    F = 20 * np.log10(F)
    freqz = np.fft.fftfreq(int(sample_count), time_step)
    print('Ran FFT')
    plt.plot(freqz, F, linewidth=0.5)
    plt.xlabel('Frequency [Hz]')
    plt.ylabel('Amplitude [dB]')
    plt.grid()
    plt.show()
    