import 'dart:async';

import 'package:network_tools/src/models/callbacks.dart';
import 'package:network_tools/src/models/open_port.dart';
import 'package:universal_io/io.dart';

/// Scans open port for a target IP or domain.
class PortScanner {
  static const int defaultStartPort = 1;
  static const int defaultEndPort = 1024;
  static const List<int> commonPorts = [
    20,
    21,
    22,
    23,
    25,
    50,
    51,
    53,
    67,
    68,
    69,
    80,
    110,
    119,
    123,
    135,
    139,
    143,
    161,
    162,
    389,
    443,
    989,
    990,
    3389
  ];

  /// Checks if the single [port] is open or not for the [target].
  static Future<OpenPort> isOpen(
    String target,
    int port, {
    Duration timeout = const Duration(milliseconds: 2000),
  }) async {
    if (port < 0 || port > 65535) {
      throw 'Provide a valid port range between '
          '0 to 65535 or startPort < endPort is not true';
    }
    final List<InternetAddress> address =
        await InternetAddress.lookup(target, type: InternetAddressType.IPv4);
    if (address.isNotEmpty) {
      final String hostIP = address[0].address;
      return connectToPort(
        activeHostsController: StreamController<OpenPort>(),
        ip: hostIP,
        port: port,
        timeout: timeout,
      );
    } else {
      throw 'Name can not be resolved';
    }
  }

  /// Scans ports only listed in [portList] for a [target]. Progress can be
  /// retrieved by [progressCallback]
  /// Tries connecting ports before until [timeout] reached.
  /// [resultsInIpAscendingOrder] = false will return results faster but not in
  /// ascending order and without [progressCallback].
  static Stream<OpenPort> customDiscover(
    String target, {
    List<int> portList = commonPorts,
    ProgressCallback? progressCallback,
    Duration timeout = const Duration(milliseconds: 2000),
    bool resultsInIpAscendingOrder = true,
  }) async* {
    final List<InternetAddress> address =
        await InternetAddress.lookup(target, type: InternetAddressType.IPv4);
    if (address.isNotEmpty) {
      final String hostIP = address[0].address;
      final List<Future<OpenPort>> openPortList = [];
      final StreamController<OpenPort> activeHostsController =
          StreamController<OpenPort>();

      for (int k = 0; k < portList.length; k++) {
        if (portList[k] >= 0 && portList[k] <= 65535) {
          openPortList.add(
            connectToPort(
              ip: hostIP,
              port: portList[k],
              timeout: timeout,
              activeHostsController: activeHostsController,
            ),
          );
        }
      }

      if (!resultsInIpAscendingOrder) {
        yield* activeHostsController.stream;
      }

      int counter = 0;

      for (final Future<OpenPort> openPortFuture in openPortList) {
        final OpenPort openPort = await openPortFuture;
        progressCallback?.call(counter * 100 / portList.length);
        yield openPort;
        counter++;
      }
    } else {
      throw 'Name can not be resolved';
    }
  }

  /// Scans port from [startPort] to [endPort] of [target]. Progress can be
  /// retrieved by [progressCallback]
  /// Tries connecting ports before until [timeout] reached.
  static Stream<OpenPort> discover(
    String target, {
    int startPort = defaultStartPort,
    int endPort = defaultEndPort,
    ProgressCallback? progressCallback,
    Duration timeout = const Duration(milliseconds: 2000),
    bool resultsInIpAscendingOrder = true,
  }) async* {
    if (startPort < 0 ||
        endPort < 0 ||
        startPort > 65535 ||
        endPort > 65535 ||
        startPort > endPort) {
      throw 'Provide a valid port range between 0 to 65535 or startPort <'
          ' endPort is not true';
    }

    final List<int> portList = [];

    for (int i = startPort; i <= endPort; ++i) {
      portList.add(i);
    }

    yield* customDiscover(
      target,
      portList: portList,
      progressCallback: progressCallback,
      timeout: timeout,
      resultsInIpAscendingOrder: resultsInIpAscendingOrder,
    );
  }

  static Future<OpenPort> connectToPort({
    required String ip,
    required int port,
    required Duration timeout,
    required StreamController<OpenPort> activeHostsController,
  }) async {
    try {
      final Socket s = await Socket.connect(ip, port, timeout: timeout);
      s.destroy();
      final OpenPort tempOpenPort = OpenPort(ip, port, isOpen: true);
      activeHostsController.add(tempOpenPort);

      return tempOpenPort;
    } catch (e) {
      if (e is! SocketException) {
        rethrow;
      }

      // Check if connection timed out or we got one of predefined errors
      if (e.osError == null || _errorCodes.contains(e.osError?.errorCode)) {
        final OpenPort tempOpenPort = OpenPort(ip, port);

        activeHostsController.add(tempOpenPort);
        return tempOpenPort;
      } else {
        // Error 23,24: Too many open files in system
        rethrow;
      }
    }
  }

  static final _errorCodes = [13, 49, 61, 64, 65, 101, 111, 113];
}
