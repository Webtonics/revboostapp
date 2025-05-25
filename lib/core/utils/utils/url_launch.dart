import 'package:url_launcher/url_launcher.dart';

void launchMyUrl(String url){
  final link = Uri.parse(url);
  launchUrl(link);
}