// lib/ui/screens/plant_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:plant_recognition_app/models/plant.dart';
import 'package:plant_recognition_app/services/database_service.dart';

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  PlantDetailScreen({required this.plant});

  @override
  _PlantDetailScreenState createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  late Plant _plant;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
  }

  void _toggleFavorite() {
    setState(() {
      _plant = _plant.copyWith(isFavorite: !_plant.isFavorite);
    });
    Provider.of<DatabaseService>(context, listen: false)
        .toggleFavorite(_plant.id!, _plant.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _plant.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: Color(0xFFDDA15E),
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
              SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _plant.imagePath,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                _plant.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                _plant.scientificName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Color(0xFFA98467),
                    ),
              ),
              SizedBox(height: 16),
              Text(
                _plant.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
