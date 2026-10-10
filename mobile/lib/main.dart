import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_config.dart';
import 'app/zelo_app.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/poppins/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Poppins'], license);
  });
  runApp(ZeloApp(config: AppConfig.fromEnvironment()));
}
