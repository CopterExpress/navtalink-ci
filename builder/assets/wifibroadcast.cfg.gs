[common]
wifi_channel = 161     # 161 -- radio channel @5825 MHz, range: 5815–5835 MHz, width 20MHz
                       # 1 -- radio channel @2412 Mhz, 
                       # see https://en.wikipedia.org/wiki/List_of_WLAN_channels for reference
wifi_region = 'BO'     # Your country for CRDA (use BO or GY if you want max tx power)
mavlink_agg_timeout = 0

[gs_mavlink]
peer = 'connect://192.168.30.2:14550'  # outgoing connection
# peer = 'listen://0.0.0.0:14550'       # incoming connection

[gs_video]
peer = 'connect://192.168.30.2:5600'  # outgoing connection for
                                      # video sink (QGroundControl on GS)
