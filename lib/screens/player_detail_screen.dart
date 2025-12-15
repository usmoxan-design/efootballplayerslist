import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/player_detail.dart';
import '../services/pes_service.dart';
import '../widgets/player_card_widget.dart';

class PlayerDetailScreen extends StatefulWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  final PesService _pesService = PesService();
  late Future<PlayerDetail> _detailFuture;
  bool _isFlipped = false;

  @override
  void initState() {
    super.initState();
    _detailFuture = _pesService.fetchPlayerDetail(widget.player);
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black as per screenshot
      appBar: AppBar(
        title: Text(
          widget.player.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<PlayerDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) return const SizedBox();

          final detail = snapshot.data!;

          // Responsive layout: Single column on mobile, row on desktop/tablet if space allows.
          // For now, we use a Column with sections, but styled to look like the distinct columns.
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Container for the main layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    // If wide enough, split into 2 or 3 columns?
                    // Let's stick to a vertical stack for mobile to ensure readability,
                    // but grouped visually.
                    return Column(
                      children: [
                        // Left Column (Card + Info)
                        _buildLeftColumn(detail),
                        const SizedBox(height: 24),
                        // Middle/Right Stats
                        _buildStatsAndSkills(detail),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftColumn(PlayerDetail detail) {
    return Column(
      children: [
        // Card Image
        PlayerCardWidget(
          player: widget.player,
          detail: detail,
          onFlip: _toggleFlip,
          isFlipped: _isFlipped,
        ),
        const SizedBox(height: 10),
        const Text(
          "Standard",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),

        // Info Table
        _buildInfoRow('Player Name', widget.player.name),
        _buildInfoRow('Squad Number', detail.stats['Squad Number'] ?? '-'),
        _buildInfoRow(
          'Team Name',
          detail.info['Team Name'] ?? widget.player.club,
        ),
        _buildInfoRow('League', detail.info['League'] ?? '-'),
        _buildInfoRow(
          'Nationality',
          detail.info['Nationality'] ?? widget.player.nationality,
        ), // Nationality might be in info or player
        _buildInfoRow('Region', detail.info['Region'] ?? '-'),
        _buildInfoRow('Height', detail.height),
        _buildInfoRow('Weight', detail.stats['Weight'] ?? '-'),
        _buildInfoRow('Age', detail.age),
        _buildInfoRow('Foot', detail.foot),
        _buildInfoRow('Maximum Level', detail.stats['Maximum Level'] ?? '-'),

        // Rating usually shown in stats, but screenshot has it here too? "Rating: C" or similar?
        // Screenshot has "Rating: C". This is Form/Condition Rating?
        // Or "Overall Rating: 85" is at top of stats.
        // Let's assume Form/Condition is separate.
        // _buildInfoRow('Rating', detail.info['Condition'] ?? '-'),
        const SizedBox(height: 10),
        // Position Row with Green Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Position:', style: TextStyle(color: Colors.grey)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                detail.position,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),
        // Mini Pitch Placeholder (Simple Visual)
        _buildMiniPitch(detail.position),
      ],
    );
  }

  Widget _buildStatsAndSkills(PlayerDetail detail) {
    // Stat list keys we want to show
    // We filter `stats` map to exclude "Squad Number", "Weight", "Maximum Level", "Age", "Height" if they leaked there.
    final excludedKeys = [
      'Squad Number',
      'Weight',
      'Maximum Level',
      'Age',
      'Height',
      'Overall Rating',
    ];
    final statEntries = detail.stats.entries
        .where((e) => !excludedKeys.contains(e.key))
        .toList();

    // Overall Rating Header
    final overallRating = detail.stats['Overall Rating'] ?? '80';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Overall Rating
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Overall Rating:",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            Text(
              overallRating,
              style: TextStyle(
                color: _getStatColor(int.tryParse(overallRating) ?? 0),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Stats List
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: statEntries.length,
          itemBuilder: (context, index) {
            final entry = statEntries[index];
            final val = int.tryParse(entry.value) ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: _getStatColor(val),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        // Additional Info usually found below stats
        _buildStatInfoRow('Weak Foot Usage', detail.info['Weak Foot Usage']),
        _buildStatInfoRow(
          'Weak Foot Accuracy',
          detail.info['Weak Foot Accuracy'],
        ),
        _buildStatInfoRow('Form', detail.info['Form']),
        _buildStatInfoRow(
          'Injury Resistance',
          detail.info['Injury Resistance'],
        ),

        const SizedBox(height: 30),

        // Skills Section
        const Text("Playing Style", style: TextStyle(color: Colors.grey)),
        Text(
          detail.playingStyle,
          style: const TextStyle(color: Colors.cyanAccent, fontSize: 16),
        ),

        const SizedBox(height: 20),
        const Text("Player Skills", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 5),
        ...detail.skills.map(
          (s) => Text(s, style: const TextStyle(color: Colors.cyanAccent)),
        ),

        const SizedBox(height: 20),
        if (detail.info.containsKey('AI Playing Styles')) ...[
          const Text("AI Playing Styles", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Text(
            detail.info['AI Playing Styles']!,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPitch(String position) {
    return Container(
      width: 100,
      height: 140,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.cyanAccent),
        color: Colors.transparent,
      ),
      child: Stack(
        children: [
          // Midfield line
          Center(child: Container(height: 1, color: Colors.cyanAccent)),
          // Center Circle
          Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          // Boxes
          Positioned(
            top: 0,
            left: 30,
            right: 30,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 30,
            right: 30,
            height: 20,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent),
              ),
            ),
          ),

          // Highlight Position
          Align(
            alignment: _getPositionAlignment(position),
            child: Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Alignment _getPositionAlignment(String position) {
    // Simple mapping
    switch (position.toUpperCase()) {
      case 'GK':
        return Alignment.bottomCenter;
      case 'CB':
        return const Alignment(0, 0.7);
      case 'LB':
        return const Alignment(-0.8, 0.7);
      case 'RB':
        return const Alignment(0.8, 0.7);
      case 'DMF':
        return const Alignment(0, 0.3);
      case 'CMF':
        return const Alignment(0, 0);
      case 'AMF':
        return const Alignment(0, -0.3);
      case 'LMF':
        return const Alignment(-0.8, 0);
      case 'RMF':
        return const Alignment(0.8, 0);
      case 'SS':
        return const Alignment(0, -0.6);
      case 'LWF':
        return const Alignment(-0.8, -0.7);
      case 'RWF':
        return const Alignment(0.8, -0.7);
      case 'CF':
        return const Alignment(0, -0.8);
      default:
        return Alignment.center;
    }
  }

  Color _getStatColor(int val) {
    if (val >= 90) return Colors.cyanAccent;
    if (val >= 80) return Colors.lightGreenAccent;
    if (val < 70) return Colors.redAccent;
    return Colors.white; // 70-79
  }

  Widget _buildStatInfoRow(String label, String? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.yellowAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
