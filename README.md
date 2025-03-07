# Network Tools

[![pub package](https://img.shields.io/pub/v/network_tools.svg)](https://pub.dev/packages/network_tools)

Network Tools Supported

1. Host Scanner

2. Port Scanner
    1. Single
    2. Range
    3. Custom

What's not supported

1. Mac Address of other devices on network

## Import package in your app

```dart
import 'package:network_tools/network_tools.dart'; 
```

## Usage

### Host Scanner

```dart
 String ip = '192.168.1.12';
  // or You can also get ip using network_info_plus package
  // final String? ip = await (NetworkInfo().getWifiIP());
  final String subnet = ip.substring(0, ip.lastIndexOf('.'));
  final stream = HostScanner.discover(subnet, firstSubnet: 1, lastSubnet: 50,
      progressCallback: (progress) {
    print('Progress for host discovery : $progress');
  });

  stream.listen((host) {
    //Same host can be emitted multiple times
    //Use Set<ActiveHost> instead of List<ActiveHost>
    print('Found device: ${host}');
  }, onDone: () {
    print('Scan completed');
  }); // Don't forget to cancel the stream when not in use.

```

### Port Scanner

```dart
  //1. Range
  String target = '192.168.1.1';
  PortScanner.discover(target, startPort: 1, endPort: 1024,
      progressCallback: (progress) {
    print('Progress for port discovery : $progress');
  }).listen((event) {
    if (event.isOpen) {
      print('Found open port : $event');
    }
  }, onDone: () {
    print('Scan completed');
  });
  //2. Single
  bool isOpen = PortScanner.isOpen(target,80);
  //3. Custom
  PortScanner.customDiscover(target, portList : const [22, 80, 139]);

```

### Run examples

1. Run host scan : `dart example/host_scan.dart`
2. Run port scan : `dart example/port_scan.dart`

## Enable Debugging

Add this code to your `main.dart` file

```dart
Logger.root.level = Level.FINE; //set to finest for detailed log
  Logger.root.onRecord.listen((record) {
    print(
        '${DateFormat.Hms().format(record.time)}: ${record.level.name}: ${record.loggerName}: ${record.message}');
  });

```

## Sample App

[Vernet](https://github.com/git-elliot/vernet) is the open source app built on top of this library.
You can check out the code and implementation for more detailed use case of this package. 

## Support and Donate

1. Support this project by becoming stargazer of this project.
2. Buy me a coffee.

    |   Bitcoin |   UPI |
    |-----------|-------|
    |<img src="https://raw.githubusercontent.com/git-elliot/network_tools/main/donation/bitcoin_qr.png" width = "100">|<img src="https://raw.githubusercontent.com/git-elliot/network_tools/main/donation/bhim_upi_qr.png" width = "100">

3. Support me on Ko-Fi

    [![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/fs0c13ty)

Inspired from [ping_discover_network](https://github.com/andrey-ushakov/ping_discover_network)
