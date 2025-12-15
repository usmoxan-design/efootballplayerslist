import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/player.dart';
import '../models/player_detail.dart';

class PesService {
  final String baseUrl = 'https://pesdb.net/pes2022/';

  Future<List<Player>> fetchPlayers({int page = 1}) async {
    try {
      // PESDB uses ?page=X for pagination
      final url = page == 1 ? baseUrl : '${baseUrl}?page=$page';
      final uri = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
          : Uri.parse(url);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        List<Player> players = [];

        var rows = document.querySelectorAll('tr');

        for (var row in rows) {
          String? name;
          String? id;
          String? club;
          String? nationality;

          var links = row.querySelectorAll('a');

          for (var link in links) {
            String href = link.attributes['href'] ?? '';
            String text = link.text.trim();

            if (href.contains('id=')) {
              if (text.isNotEmpty) {
                name = text;
                Uri uri = Uri.parse(
                  href.startsWith('?') ? 'http://fake$href' : href,
                );
                if (uri.queryParameters.containsKey('id')) {
                  id = uri.queryParameters['id'];
                }
              }
            } else if (href.contains('club_team=')) {
              club = text;
            } else if (href.contains('nationality=')) {
              nationality = text;
            }
          }

          if (id != null && name != null) {
            players.add(
              Player(
                id: id,
                name: name,
                club: club ?? 'Free Agent',
                nationality: nationality ?? 'Unknown',
              ),
            );
          }
        }
        return players;
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching players: $e');
      rethrow;
    }
  }

  Future<PlayerDetail> fetchPlayerDetail(Player player) async {
    try {
      final url = '$baseUrl?id=${player.id}';
      final uri = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
          : Uri.parse(url);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);

        // Default values
        String position = 'Unknown';
        String height = 'Unknown';
        String age = 'Unknown';
        String foot = 'Unknown';
        String playingStyle = 'Unknown';
        List<String> skills = [];
        Map<String, String> stats = {};
        Map<String, String> info = {};

        // Find standard rows
        var rows = document.querySelectorAll('tr');
        for (var row in rows) {
          var th = row.querySelector('th');
          var td = row.querySelector('td');

          if (th != null && td != null) {
            String header = th.text.trim().replaceAll(':', ''); // Remove colon
            String value = td.text.trim();

            if (header == 'Position') {
              position = value;
            } else if (header == 'Height') {
              height = value;
            } else if (header == 'Age') {
              age = value;
            } else if (header == 'Foot') {
              foot = value;
            } else if (header == 'Playing Style') {
              playingStyle = value;
            } else if (header == 'Player Skills') {
              // Get all text content and split by newlines/br tags
              String skillsText = td.text.trim();
              if (skillsText.isNotEmpty) {
                // Split by newlines and filter empty strings
                var skillsList = skillsText
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                skills.addAll(skillsList);
              }

              // Also try to get from individual text nodes if above didn't work
              if (skills.isEmpty) {
                for (var node in td.nodes) {
                  if (node.nodeType == Node.TEXT_NODE) {
                    var val = node.text?.trim();
                    if (val != null && val.isNotEmpty) {
                      skills.add(val);
                    }
                  }
                }
              }
            } else if (header == 'AI Playing Styles') {
              // Get all text content and split by newlines
              String aiStylesText = td.text.trim();
              List<String> styles = [];

              if (aiStylesText.isNotEmpty) {
                styles = aiStylesText
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
              }

              // Fallback to node iteration
              if (styles.isEmpty) {
                for (var node in td.nodes) {
                  if (node.nodeType == Node.TEXT_NODE) {
                    var val = node.text?.trim();
                    if (val != null && val.isNotEmpty) {
                      styles.add(val);
                    }
                  }
                }
              }

              if (styles.isNotEmpty) {
                info[header] = styles.join('\n');
              }
            } else {
              // Collect numeric stats
              if (RegExp(r'^\d+$').hasMatch(value)) {
                stats[header] = value;
              } else {
                // Collect other text info (League, Team, Region, etc)
                info[header] = value;
              }
            }
          }
        }

        return PlayerDetail(
          player: player,
          position: position,
          height: height,
          age: age,
          foot: foot,
          stats: stats,
          info: info,
          playingStyle: playingStyle,
          skills: skills,
        );
      } else {
        throw Exception(
          'Failed to load player details: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching player details: $e');
      rethrow;
    }
  }
}
