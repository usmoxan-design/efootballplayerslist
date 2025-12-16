import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import '../models/player.dart';
import '../models/player_detail.dart';
import '../models/category.dart';

class PesService {
  final String listingUrl = 'https://pesdb.net/efootball/';
  // 'https://pesdb.net/efootball/?all=1&featured=epic-italian-league-attackers-dec-15-25';
  final String detailBaseUrl = 'https://pesdb.net/efootball/';

  Future<List<Category>> fetchCategories() async {
    try {
      final uri = kIsWeb
          ? Uri.parse(
              'https://corsproxy.io/?${Uri.encodeComponent(detailBaseUrl)}',
            )
          : Uri.parse(detailBaseUrl);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        var document = parser.parse(response.body);
        List<Category> categories = [];

        var shortcuts = document.querySelector('div.shortcuts');
        if (shortcuts != null) {
          var links = shortcuts.querySelectorAll('a');
          for (var link in links) {
            String name = link.text.trim();
            String href = link.attributes['href'] ?? '';
            if (name.isNotEmpty && href.isNotEmpty) {
              // Ensure we assume these are relative paths or full query params
              String fullUrl = href.startsWith('http')
                  ? href
                  : '$detailBaseUrl$href';
              categories.add(Category(name: name, url: fullUrl));
            }
          }
        }
        return categories;
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  Future<List<Player>> fetchPlayers({String? customUrl, int page = 1}) async {
    try {
      // Use customUrl if provided, otherwise default listingUrl
      String baseUrlToUse = customUrl ?? listingUrl;

      // Handle pagination
      String url = baseUrlToUse;
      if (page > 1) {
        url += (url.contains('?') ? '&' : '?') + 'page=$page';
      }

      print('Fetching URL: $url'); // Debugging

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
                // Handle different href formats
                Uri uri;
                try {
                  if (href.startsWith('http')) {
                    uri = Uri.parse(href);
                  } else {
                    uri = Uri.parse(
                      'http://fake.com/${href.startsWith('/') ? href.substring(1) : href}',
                    );
                  }

                  if (uri.queryParameters.containsKey('id')) {
                    id = uri.queryParameters['id'];
                  }
                } catch (e) {
                  print('Error parsing ID uri: $href');
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

  Future<PlayerDetail> fetchPlayerDetail(
    Player player, {
    String mode = 'level1',
  }) async {
    try {
      // Use the clean detailBaseUrl for details
      String url = '$detailBaseUrl?id=${player.id}';
      if (mode == 'max_level') {
        url += '&mode=max_level';
      }

      final uri = kIsWeb
          ? Uri.parse('https://corsproxy.io/?${Uri.encodeComponent(url)}')
          : Uri.parse(url);
      print(uri);
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
        Map<String, int> suggestedPoints = {};

        // Find standard rows
        var rows = document.querySelectorAll('tr');
        for (var row in rows) {
          var th = row.querySelector('th');
          var td = row.querySelector('td');

          if (th != null && td != null) {
            String headerOriginal = th.text.trim().replaceAll(':', '').trim();
            String header = headerOriginal.toLowerCase();
            String value = td.text.trim();

            if (header == 'position') {
              position = value;
            } else if (header == 'height') {
              height = value;
            } else if (header == 'age') {
              age = value;
            } else if (header == 'foot') {
              foot = value;
            } else if (header == 'playing_styles') {
              playingStyle = value;
            } else if (header == 'player skills') {
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
            } else if (header == 'ai playing styles') {
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
                info[headerOriginal] = styles.join('\n');
              }
            } else {
              // Collect numeric stats
              // Matches "95" or "(+10) 95"
              if (RegExp(r'^(\(\+\d+\)\s*)?\d+$').hasMatch(value)) {
                stats[headerOriginal] = value;
              } else {
                // Collect other text info (League, Team, Region, etc)
                info[headerOriginal] = value;
              }
            }
          } else {
            // Check for suggested progression points (nested within a td/div)
            var td = row.querySelector('td');
            if (td != null && td.text.contains('Suggested points')) {
              var innerDivs = td.querySelectorAll('div');
              for (var div in innerDivs) {
                // formatting is usually: <div>&bull; Passing:<span ...>4</span></div>
                if (div.querySelector('span') != null &&
                    div.text.contains(':')) {
                  var text = div.text.trim();
                  // Remove bullet and clean up
                  // text might be "• Passing:4" or "• Passing: 4"
                  var parts = text.split(':');
                  if (parts.length >= 2) {
                    String key = parts[0]
                        .replaceAll(RegExp(r'[•\u2022]'), '') // bullets
                        .replaceAll('&bull;', '')
                        .trim();

                    var span = div.querySelector('span');
                    if (span != null) {
                      String valStr = span.text.trim();
                      int? val = int.tryParse(valStr);
                      if (val != null) {
                        suggestedPoints[key] = val;
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // Special handling for the playing_styles nested table
        var playingStylesTable = document.querySelector('table.playing_styles');
        if (playingStylesTable != null) {
          var styleRows = playingStylesTable.querySelectorAll('tr');
          String currentSection = '';

          for (var row in styleRows) {
            var th = row.querySelector('th');
            if (th != null) {
              // This is a header row, determining the section
              String header = th.text.trim().toLowerCase();
              if (header == 'playing style') {
                currentSection = 'playing_style';
              } else if (header == 'player skills') {
                currentSection = 'player_skills';
              } else {
                currentSection =
                    ''; // Ignore other sections like AI Playing Styles
              }
            } else {
              // This is a value row
              var td = row.querySelector('td');
              if (td != null) {
                String value = td.text.trim();
                if (value.isNotEmpty) {
                  if (currentSection == 'playing_style') {
                    playingStyle = value;
                  } else if (currentSection == 'player_skills') {
                    skills.add(value);
                  }
                }
              }
            }
          }
        }

        // Parse description
        String description = '';
        var bottomDesc = document.querySelector('.bottom-description h2');
        if (bottomDesc != null) {
          description = bottomDesc.text.trim();
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
          suggestedPoints: suggestedPoints,
          description: description,
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
