import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_theme.dart';

class MeterMapView extends StatefulWidget {
  const MeterMapView({super.key});

  @override
  State<MeterMapView> createState() => _MeterMapViewState();
}

class _MeterMapViewState extends State<MeterMapView> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(6.5244, 3.3792); // Lagos coordinates

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Basic Map Placeholder
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),

          // Floating Search Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            right: 20,
            child: _buildFloatingSearchBar(),
          ),

          // Zoom Controls
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height * 0.35,
            child: Column(
              children: [
                _buildMapControl(Icons.add, () => mapController.animateCamera(CameraUpdate.zoomIn())),
                const SizedBox(height: 8),
                _buildMapControl(Icons.remove, () => mapController.animateCamera(CameraUpdate.zoomOut())),
                const SizedBox(height: 8),
                _buildMapControl(Icons.my_location, () {}),
              ],
            ),
          ),

          // Bottom Categories
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _buildBottomCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Search locations or meter ID',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          suffixIcon: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                VerticalDivider(indent: 16, endIndent: 16),
                SizedBox(width: 8),
                Icon(Icons.tune, color: AppTheme.primary),
              ],
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildMapControl(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: Icon(icon, color: AppTheme.primary, size: 20),
      ),
    );
  }

  Widget _buildBottomCategories() {
    return Container(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildCategoryItem('All Meters', Icons.electric_meter, true),
          _buildCategoryItem('Postpaid', Icons.receipt_long_outlined, false),
          _buildCategoryItem('Prepaid', Icons.bolt, false),
          _buildCategoryItem('Faulty', Icons.warning_amber_rounded, false),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String label, IconData icon, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 120,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primary : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isActive ? Colors.white : AppTheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : AppTheme.textDark,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
