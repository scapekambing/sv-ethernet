#include <stdio.h>
#include "led_ctrl.hpp"

uint8_t ledCtrl::get_num_leds(void)
{
    return num_leds;
}

void ledCtrl::set_num_leds(uint8_t n)
{
    num_leds = n;
}

int main()
{
    ledCtrl led;
    led.set_num_leds(4);
    printf("Number of LEDs: %d\n", led.get_num_leds());
    return 0;
}