installing
==========
```shell
gem install presbeus
```
configuring
===========
you need to create `~/.config/presbeus.yml` with:
```shell
password_command: /command_line/outputing/your/password
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
presbeus.rb sms mydeviceid phonenumber text for your SMS
```