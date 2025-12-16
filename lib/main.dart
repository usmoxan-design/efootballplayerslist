import 'package:efootballtest/screens/categories_screen.dart';
import 'package:efootballtest/widgets/player_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/pes_service.dart';
import 'models/player.dart';
import 'screens/player_detail_screen.dart';

void main() {
  runApp(const EfootballApp());
}

class EfootballApp extends StatelessWidget {
  const EfootballApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eFootball DB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E27),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1B4B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _selectedCategoryUrl;

  // Key to force PlayersScreen refresh when category changes
  Key _playersScreenKey = UniqueKey();

  void _onCategorySelected(String url) {
    setState(() {
      _selectedCategoryUrl = url;
      _currentIndex = 1; // Switch to Players tab
      _playersScreenKey = UniqueKey(); // Refresh players screen
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Categories
          Scaffold(
            appBar: AppBar(
              title: const Text('Categories'),
              backgroundColor: const Color(0xFF1E1B4B),
            ),
            body: CategoriesScreen(onCategorySelected: _onCategorySelected),
          ),
          // Tab 1: Players
          PlayersScreen(
            key: _playersScreenKey,
            initialUrl: _selectedCategoryUrl,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        backgroundColor: const Color(0xFF1E1B4B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Players',
          ),
        ],
      ),
    );
  }
}

class PlayersScreen extends StatefulWidget {
  final String? initialUrl;
  const PlayersScreen({super.key, this.initialUrl});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final PesService _pesService = PesService();
  List<Player> _players = [];
  int _currentPage = 1;
  int _totalPages = 10; // Estimate
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPlayers = await _pesService.fetchPlayers(
        page: _currentPage,
        customUrl:
            widget.initialUrl, // Use custom URL if passed from categories
      );
      setState(() {
        _players = newPlayers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading players: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    setState(() {
      _currentPage = page;
    });
    _loadPlayers();
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    await _loadPlayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF1E1B4B),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'eFootball Players',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1).withOpacity(0.3),
                      const Color(0xFF1E1B4B),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Grid Content
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final player = _players[index];
                      return _buildModernPlayerCard(player);
                    }, childCount: _players.length),
                  ),
                ),

          // Pagination
          if (_players.isNotEmpty)
            SliverToBoxAdapter(child: _buildPagination()),

          // Bottom spacing
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildModernPlayerCard(Player player) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(player: player),
          ),
        );
      },
      child: Hero(
        tag: player.id,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1E1B4B), const Color(0xFF0A0E27)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // Glow effect
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF6366F1).withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Card content
                PlayerCardWidget(player: player),

                // Overlay gradient for better text visibility
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 12,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                player.club,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B4B),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // First page
          _buildPaginationButton(
            icon: Icons.keyboard_double_arrow_left_rounded,
            onTap: () => _goToPage(1),
            enabled: _currentPage > 1,
          ),
          const SizedBox(width: 8),

          // Previous page
          _buildPaginationButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _goToPage(_currentPage - 1),
            enabled: _currentPage > 1,
          ),
          const SizedBox(width: 16),

          // Page numbers
          ..._buildPageNumbers(),

          const SizedBox(width: 16),

          // Next page
          _buildPaginationButton(
            icon: Icons.chevron_right_rounded,
            onTap: () => _goToPage(_currentPage + 1),
            enabled: _currentPage < _totalPages,
          ),
          const SizedBox(width: 8),

          // Last page
          _buildPaginationButton(
            icon: Icons.keyboard_double_arrow_right_rounded,
            onTap: () => _goToPage(_totalPages),
            enabled: _currentPage < _totalPages,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pages = [];
    int start = (_currentPage - 2).clamp(1, _totalPages);
    int end = (_currentPage + 2).clamp(1, _totalPages);

    // Show first page if not in range
    if (start > 1) {
      pages.add(_buildPageNumber(1));
      if (start > 2) {
        pages.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.white54)),
          ),
        );
      }
    }

    // Show page range
    for (int i = start; i <= end; i++) {
      pages.add(_buildPageNumber(i));
    }

    // Show last page if not in range
    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        pages.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: TextStyle(color: Colors.white54)),
          ),
        );
      }
      pages.add(_buildPageNumber(_totalPages));
    }

    return pages;
  }

  Widget _buildPageNumber(int page) {
    final isActive = page == _currentPage;
    return GestureDetector(
      onTap: () => _goToPage(page),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? const Color(0xFF6366F1).withOpacity(0.2)
              : Colors.transparent,

          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? const Color(0xFF6366F1)
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFF6366F1) : Colors.white24,
          size: 20,
        ),
      ),
    );
  }
}
