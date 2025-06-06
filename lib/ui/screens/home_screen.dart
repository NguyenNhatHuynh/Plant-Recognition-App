// lib/ui/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:plant_recognition_app/ui/screens/camera_screen.dart';
import 'package:plant_recognition_app/ui/screens/library_screen.dart';
import 'package:plant_recognition_app/ui/screens/history_screen.dart';
import 'package:plant_recognition_app/ui/screens/plant_detail_screen.dart';
import 'package:plant_recognition_app/ui/widgets/plant_card.dart';
import 'package:plant_recognition_app/models/plant.dart';
import 'package:provider/provider.dart';
import 'package:plant_recognition_app/services/database_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _controller.reset();
    _controller.forward();
  }

  Widget _buildHomeTab(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    return SafeArea(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0.0, 20.0 * (1.0 - _animation.value)),
            child: Opacity(
              opacity: _animation.value,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2D6A4F), Color(0xFF4CAF50)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'My Plants',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.search,
                                        color: Colors.white70),
                                    onPressed: () {},
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.add_circle_outline,
                                        color: Colors.white70),
                                    onPressed: () {},
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),

                      // Scan Button with Animation
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => CameraScreen(),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              transitionDuration: Duration(milliseconds: 300),
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner,
                                  color: Color(0xFF2D6A4F), size: 28),
                              SizedBox(width: 12),
                              Text(
                                'Scan & Identify Plant',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Color(0xFF2D6A4F),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),

                      // Popular Plants Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Popular Plants',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A4F),
                                ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      FutureBuilder<List<Plant>>(
                        future: dbService.getFavorites(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return Text('No favorite plants');
                          }
                          final plants = snapshot.data!;
                          return SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: plants.length > 2 ? 2 : plants.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            PlantDetailScreen(
                                                plant: plants[index]),
                                        transitionsBuilder:
                                            (_, animation, __, child) {
                                          return FadeTransition(
                                              opacity: animation, child: child);
                                        },
                                        transitionDuration:
                                            Duration(milliseconds: 300),
                                      ),
                                    );
                                  },
                                  child: Hero(
                                    tag: 'plant-${plants[index].id}',
                                    child: PlantCard(
                                      plant: plants[index],
                                      onTap: () {},
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 32),

                      // Library Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Plant Library',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A4F),
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => LibraryScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      FutureBuilder<List<Plant>>(
                        future: dbService.getHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return Text('No plants in library');
                          }
                          final plants = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: plants.length > 2 ? 2 : plants.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          PlantDetailScreen(
                                              plant: plants[index]),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                      transitionDuration:
                                          Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'plant-${plants[index].id}',
                                  child: PlantCard(
                                    plant: plants[index],
                                    onTap: () {},
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: 32),

                      // History Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recognition History',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D6A4F),
                                ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, __, ___) => HistoryScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return FadeTransition(
                                        opacity: animation, child: child);
                                  },
                                  transitionDuration:
                                      Duration(milliseconds: 300),
                                ),
                              );
                            },
                            child: Text(
                              'View All',
                              style: TextStyle(color: Color(0xFF4CAF50)),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      FutureBuilder<List<Plant>>(
                        future: dbService.getHistory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || snapshot.data == null) {
                            return Text('No history');
                          }
                          final plants = snapshot.data!;
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: plants.length > 2 ? 2 : plants.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    PageRouteBuilder(
                                      pageBuilder: (_, __, ___) =>
                                          PlantDetailScreen(
                                              plant: plants[index]),
                                      transitionsBuilder:
                                          (_, animation, __, child) {
                                        return FadeTransition(
                                            opacity: animation, child: child);
                                      },
                                      transitionDuration:
                                          Duration(milliseconds: 300),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'plant-${plants[index].id}',
                                  child: PlantCard(
                                    plant: plants[index],
                                    onTap: () {},
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildHomeTab(context),
      LibraryScreen(),
      HistoryScreen(),
      // Favorites tab: bạn có thể tạo một màn hình riêng cho Favorites nếu muốn
      Center(child: Text('Favorites', style: TextStyle(fontSize: 24))),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: 'Favorites'),
        ],
      ),
    );
  }
}
