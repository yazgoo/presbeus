[![Gem Version](https://badge.fury.io/rb/presbeus.svg)](https://badge.fury.io/rb/presbeus)

Screenshot
==========

![screenshot](https://raw.githubusercontent.com/yazgoo/presbeus/master/screenshot.png)

installing
==========
```shell
gem install presbeus
```
configuring
===========
you need to create `~/.config/presbeus.yml` with:
```yaml
password_command: /command_line/outputing/your/api/key
```
For example, if the api key is `my-api-key` it could be (though it is not secure):
```yaml
password_command: echo my-api-key
```
You can configure a default device (see presbeus devices in `using`)
```yaml
default_device: uYourDefaultDeviceID
```
using
=====
list your devices:

```shell
$ presbeus devices
mydeviceid  MYDEVICE
```

list your SMS threads or a given device:

```shell
$ presbeus threads mydeviceid
1  Someone
2  Someone Else
```

list your SMS for a given device / thread:

```shell
$ presbeus thread mydeviceid 2
```

send an SMS:

```shell
presbeus sms mydeviceid phonenumber text for your SMS
```

show last active thread

```shell
$ presbeus last mydeviceid
```

To enable desktop notifications, you need to add to `~/.config/presbeus.yml`:

```yaml
notify_command: notify-send
```

And then you need to start presbeus in realtime mode:

```shell
$ presbeus realtime
```
