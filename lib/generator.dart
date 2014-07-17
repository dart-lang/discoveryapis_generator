library discovery_api_client_generator;

import "dart:io";
import "dart:async";
import 'package:google_discovery_v1_api/discovery_v1_api_client.dart';
import 'package:google_discovery_v1_api/discovery_v1_api_console.dart';

part "src/apis_package_generator.dart";
part "src/config.dart";
part "src/dart_api_library.dart";
part "src/dart_api_test_library.dart";
part "src/dart_comments.dart";
part "src/dart_resources.dart";
part "src/dart_schemas.dart";
part "src/namer.dart";
part "src/utils.dart";
part "src/uri_template.dart";

List<GenerateResult> generateApiPackage(
    List<RestDescription> descriptions, String outputDirectory) {
  var config = new Config('googleapis', '0.1.0-dev');
  var apisPackageGenerator = new ApisPackageGenerator(
      descriptions, config, outputDirectory);

  return apisPackageGenerator.generateApiPackage();
}

Future<RestDescription> fetchApiDescriptions(String name, String version) {
  return _discoveryClient.apis.getRest(name, version);
}

Future<GenerateResult> generateLibrary(
    String apiName, String apiVersion, String output) {

  return fetchApiDescriptions(apiName, apiVersion).then((RestDescription doc) {
    return generateApiPackage([doc], output).first;
  });
}

Future<List<GenerateResult>> generateAllLibraries(String outputDirectory) {
  var apiDescriptions = <RestDescription>[];

  return _discoveryClient.apis.list().then((DirectoryList list) {
    var futures = <Future>[];
    for (var item in list.items) {
      futures.add(fetchApiDescriptions(item.name, item.version).then((doc) {
        apiDescriptions.add(doc);
      }));
    }
    return Future.wait(futures);
  }).then((_) {
    return generateApiPackage(apiDescriptions, outputDirectory);
  });
}

class GenerateResult {
  final String apiName;
  final String apiVersion;
  final String message;
  final String packagePath;

  GenerateResult(this.apiName, this.apiVersion, this.packagePath)
      : message = '' {
    assert(this.apiName != null);
    assert(this.apiVersion != null);
    assert(this.packagePath != null);
  }

  GenerateResult.error(
     this.apiName, this.apiVersion, this.packagePath, this.message) {
    assert(this.apiName != null);
    assert(this.apiVersion != null);
    assert(this.packagePath != null);
    assert(this.message != null);
  }

  bool get success => message.isEmpty;

  String get shortName
      => cleanName("${apiName}_${apiVersion}_api").toLowerCase();

  String toString() {
    var flag = success ? '[SUCCESS]' : '[FAIL]';
    var msg = message != null && !message.isEmpty ? ':\n  => $message' : '';
    return '$flag $apiName $apiVersion @ $packagePath $msg';
  }
}

final _discoveryClient = new Discovery();
