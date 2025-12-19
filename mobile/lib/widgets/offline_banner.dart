import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  
  const OfflineBanner({
    super.key,
    required this.child,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> with SingleTickerProviderStateMixin {
  final ConnectivityService _connectivityService = ConnectivityService();
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  bool _showBanner = false;
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _heightAnimation = Tween<double>(
      begin: 0.0,
      end: 40.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _connectivityService.addListener(_updateConnectivityStatus);
    _updateConnectivityStatus();
  }
  
  void _updateConnectivityStatus() {
    final isOffline = !_connectivityService.isOnline;
    
    if (isOffline != _showBanner) {
      setState(() {
        _showBanner = isOffline;
      });
      
      if (_showBanner) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }
  
  @override
  void dispose() {
    _connectivityService.removeListener(_updateConnectivityStatus);
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _heightAnimation,
          builder: (context, child) {
            return Container(
              height: _heightAnimation.value,
              width: double.infinity,
              color: Colors.red.shade700,
              child: _heightAnimation.value > 0
                  ? Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'You are offline. Some features may be limited.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            );
          },
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
