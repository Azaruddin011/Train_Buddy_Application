import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/skeleton_loader.dart';
import '../utils/accessibility_utils.dart';
import '../services/auth_service.dart';
import '../services/api_client.dart';
import '../config/app_config.dart';
import '../services/token_store.dart';

class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  
  // Performance optimization flags
  bool _useSimpleAnimations = false;
  bool _reduceMotion = false;
  bool _lowPowerMode = false;
  
  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller with default settings
    // We'll update these in didChangeDependencies after we have context
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _scrollController.addListener(() {
      // Only update state if we're not in low power mode
      if (!_lowPowerMode) {
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      } else if (_scrollController.offset % 100 == 0) {
        // In low power mode, update less frequently
        setState(() {
          _scrollOffset = _scrollController.offset;
        });
      }
    });
    
    // Simulate loading delay
    _loadData();
    
    // Set system UI overlay style for immersive experience
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1A237E),
      systemNavigationBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Now that we have context, check device capabilities
    _checkDeviceCapabilities();
    
    // Update animation controller based on device capabilities
    _updateAnimationSettings();
  }
  
  void _updateAnimationSettings() {
    // Update animation duration based on device capabilities
    _animationController.duration = Duration(seconds: _useSimpleAnimations ? 30 : 20);
    
    // Start or stop animations based on accessibility settings
    if (_reduceMotion && _animationController.isAnimating) {
      _animationController.stop();
    } else if (!_reduceMotion && !_animationController.isAnimating) {
      _animationController.repeat();
    }
  }
  
  void _checkDeviceCapabilities() {
    // Check device memory and processing power
    try {
      // Get device info - in a real app, we'd use a package like device_info_plus
      final deviceData = MediaQuery.of(context);
      final screenSize = deviceData.size;
      final pixelRatio = deviceData.devicePixelRatio;
      
      // Calculate approximate device capability score
      // Lower-end devices typically have lower resolution or pixel ratio
      final deviceScore = screenSize.width * screenSize.height * pixelRatio;
      
      // Set flags based on device score
      setState(() {
        _useSimpleAnimations = deviceScore < 1000000; // Threshold for lower-end devices
        _lowPowerMode = deviceScore < 800000;  // Threshold for very low-end devices
      });
      
      // Check for reduced motion accessibility setting
      _reduceMotion = deviceData.disableAnimations;
      
      print('Device optimization: Simple animations: $_useSimpleAnimations, Low power: $_lowPowerMode, Reduce motion: $_reduceMotion');
    } catch (e) {
      // If we can't determine device capabilities, default to safe options
      _useSimpleAnimations = false;
      _lowPowerMode = false;
      _reduceMotion = false;
    }
  }
  
  void _checkAccessibilityChanges() {
    if (mounted && context != null) {
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion != _reduceMotion) {
        setState(() {
          _reduceMotion = reduceMotion;
          
          // Update animation controller based on new setting
          if (_reduceMotion && _animationController.isAnimating) {
            _animationController.stop();
          } else if (!_reduceMotion && !_animationController.isAnimating) {
            _animationController.repeat();
          }
        });
      }
    }
  }

  /// Simulate loading data from API
  Future<void> _loadData() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A237E),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, math.sin(_animationController.value * math.pi * 2) * 3),
              child: const Text(
                'TrainBuddy',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            );
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final authService = AuthService(apiClient: ApiClient(
                baseUrl: AppConfig.backendBaseUrl,
                tokenProvider: () => TokenStore.token,
              ));
              await authService.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animated background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: BackgroundPainter(
                    animation: _animationController.value,
                    scrollOffset: _scrollOffset,
                    useSimpleAnimations: _useSimpleAnimations,
                    lowPowerMode: _lowPowerMode,
                  ),
                );
              },
            ),
          ),
          
          // Main content
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Show skeleton UI while loading
                if (_isLoading) ..._buildSkeletonUI() else ...[
                // Welcome header
                SliverToBoxAdapter(
                  child: _buildWelcomeHeader(),
                ),
                
                // Section title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Core Services',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Core services grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildListDelegate([
                      _build3DCard(
                        context,
                        'Seek Buddy',
                        'Connect with confirmed passengers',
                        Icons.people,
                        const Color(0xFF00BCD4),
                        () => Navigator.pushNamed(context, '/find-buddy-intro'),
                      ),
                      _build3DCard(
                        context,
                        'Check PNR',
                        'Get journey status',
                        Icons.confirmation_number,
                        const Color(0xFFFF5722),
                        () => Navigator.pushNamed(context, '/pnr'),
                      ),
                      _build3DCard(
                        context,
                        'Offer Seat',
                        'Help waitlisted passengers',
                        Icons.airline_seat_recline_normal,
                        const Color(0xFF4CAF50),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Offer seat feature coming soon!')),
                          );
                        },
                      ),
                      _build3DCard(
                        context,
                        'Confirmation',
                        'Check confirmation chances',
                        Icons.trending_up,
                        const Color(0xFF9C27B0),
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Confirmation feature coming soon!')),
                          );
                        },
                      ),
                    ]),
                  ),
                ),
                
                // Train services section title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Row(
                      children: [
                        Text(
                          'Train Services',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Train services horizontal list
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 180,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildHorizontalCard(
                          context,
                          'Train Search',
                          'Find trains between stations',
                          Icons.train,
                          const Color(0xFF2196F3),
                          () => Navigator.pushNamed(context, '/train-search'),
                        ),
                        _buildHorizontalCard(
                          context,
                          'Live Status',
                          'Track your train in real-time',
                          Icons.location_on,
                          const Color(0xFFE91E63),
                          () => Navigator.pushNamed(context, '/live-status'),
                        ),
                        _buildHorizontalCard(
                          context,
                          'Seat Availability',
                          'Check seat status',
                          Icons.event_seat,
                          const Color(0xFFFF9800),
                          () => Navigator.pushNamed(context, '/seat-availability'),
                        ),
                        _buildHorizontalCard(
                          context,
                          'Train Schedule',
                          'View detailed timetables',
                          Icons.schedule,
                          const Color(0xFF673AB7),
                          () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Train schedule feature coming soon!')),
                            );
                          },
                        ),
                        _buildHorizontalCard(
                          context,
                          'Fare Enquiry',
                          'Check ticket prices',
                          Icons.attach_money,
                          const Color(0xFF009688),
                          () => Navigator.pushNamed(context, '/fare-enquiry'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Premium features section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    child: Text(
                      'Premium Features',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                
                // Premium feature card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildPremiumCard(context),
                  ),
                ),
                
                // Bottom padding
                const SliverToBoxAdapter(
                  child: SizedBox(height: 40),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF303F9F), Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.train_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to TrainBuddy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your ultimate train companion',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildInfoChip(Icons.people_alt, 'Connect'),
              _buildInfoChip(Icons.confirmation_number, 'PNR'),
              _buildInfoChip(Icons.train, 'Live Status'),
              _buildInfoChip(Icons.event_seat, 'Seats'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _build3DCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // Adjust for accessibility
    final reduceMotion = AccessibilityUtils.hasReducedMotion(context);
    final highContrast = AccessibilityUtils.hasHighContrast(context);
    final largeText = AccessibilityUtils.hasLargeText(context);
    
    // Create semantic label for screen readers
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      title: title,
      description: subtitle,
      action: 'Double tap to open $title',
    );
    
    // Adjust colors for high contrast mode
    final cardColor = highContrast ? Colors.blue.shade700 : color;
    final textColor = highContrast ? Colors.white : Colors.white;
    final subtitleColor = highContrast ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7);
    
    // Adjust animation duration for reduced motion
    final animDuration = reduceMotion ? const Duration(milliseconds: 100) : const Duration(milliseconds: 500);
    
    // Adjust text size for large text mode
    final titleSize = AccessibilityUtils.getScaledFontSize(context, 18);
    final subtitleSize = AccessibilityUtils.getScaledFontSize(context, 12);
    final iconSize = AccessibilityUtils.getScaledIconSize(context, 40);
    
    return Semantics(
      label: semanticLabel,
      button: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: animDuration,
        builder: (context, value, child) {
          return Transform.translate(
            offset: reduceMotion ? Offset.zero : Offset(0, 50 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, reduceMotion ? 0 : 0.001)
                  ..rotateX(reduceMotion ? 0 : 0.05)
                  ..rotateY(reduceMotion ? 0 : 0.05),
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cardColor,
                          highContrast ? cardColor : Color.lerp(cardColor, Colors.black, 0.3)!,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cardColor.withOpacity(highContrast ? 0.8 : 0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(highContrast ? 0.8 : 0.5),
                              width: highContrast ? 2 : 1,
                            ),
                            left: BorderSide(
                              color: Colors.white.withOpacity(highContrast ? 0.6 : 0.3),
                              width: highContrast ? 2 : 1,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: largeText 
                              ? const EdgeInsets.all(24) 
                              : const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                icon,
                                size: iconSize,
                                color: textColor,
                              ),
                              SizedBox(height: largeText ? 20 : 16),
                              Text(
                                title,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: largeText ? 10 : 8),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: subtitleSize,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    // Adjust for accessibility
    final reduceMotion = AccessibilityUtils.hasReducedMotion(context);
    final highContrast = AccessibilityUtils.hasHighContrast(context);
    final largeText = AccessibilityUtils.hasLargeText(context);
    
    // Create semantic label for screen readers
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      title: title,
      description: subtitle,
      action: 'Double tap to open $title',
    );
    
    // Adjust colors for high contrast mode
    final cardColor = highContrast ? Colors.blue.shade700 : color;
    final textColor = highContrast ? Colors.white : Colors.white;
    final subtitleColor = highContrast ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.7);
    
    // Adjust text size for large text mode
    final titleSize = AccessibilityUtils.getScaledFontSize(context, 16);
    final subtitleSize = AccessibilityUtils.getScaledFontSize(context, 12);
    final iconSize = AccessibilityUtils.getScaledIconSize(context, 36);
    
    // Adjust width for large text
    final cardWidth = largeText ? 180.0 : 160.0;
    
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  cardColor,
                  highContrast ? cardColor : Color.lerp(cardColor, Colors.black, 0.3)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withOpacity(highContrast ? 0.6 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withOpacity(highContrast ? 0.6 : 0.3),
                      width: highContrast ? 2 : 1,
                    ),
                    left: BorderSide(
                      color: Colors.white.withOpacity(highContrast ? 0.5 : 0.2),
                      width: highContrast ? 2 : 1,
                    ),
                  ),
                ),
                child: Padding(
                  padding: largeText 
                      ? const EdgeInsets.all(20) 
                      : const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: iconSize,
                        color: textColor,
                      ),
                      SizedBox(height: largeText ? 16 : 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: textColor,
                          fontSize: titleSize,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: largeText ? 8 : 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: subtitleSize,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    // Adjust for accessibility
    final reduceMotion = AccessibilityUtils.hasReducedMotion(context);
    final highContrast = AccessibilityUtils.hasHighContrast(context);
    final largeText = AccessibilityUtils.hasLargeText(context);
    
    // Create semantic label for screen readers
    final semanticLabel = AccessibilityUtils.createSemanticLabel(
      title: 'Premium Coordination',
      description: 'Guaranteed seat for waitlisted passengers',
      action: 'Double tap to upgrade to premium',
    );
    
    // Adjust colors for high contrast mode
    final gradientStart = highContrast ? Colors.orange.shade700 : const Color(0xFFFFD700);
    final gradientEnd = highContrast ? Colors.orange.shade900 : const Color(0xFFFFA000);
    final textColor = highContrast ? Colors.white : Colors.white;
    final subtitleColor = highContrast ? Colors.white.withOpacity(0.9) : Colors.white70;
    final buttonColor = highContrast ? Colors.black : Colors.white;
    final buttonTextColor = highContrast ? Colors.white : const Color(0xFFFF9800);
    
    // Adjust text size for large text mode
    final titleSize = AccessibilityUtils.getScaledFontSize(context, 18);
    final subtitleSize = AccessibilityUtils.getScaledFontSize(context, 12);
    final buttonTextSize = AccessibilityUtils.getScaledFontSize(context, 16);
    final iconSize = AccessibilityUtils.getScaledIconSize(context, 24);
    
    // Adjust padding for large text
    final contentPadding = largeText ? const EdgeInsets.all(24) : const EdgeInsets.all(20);
    final buttonPadding = largeText 
        ? const EdgeInsets.symmetric(vertical: 16) 
        : const EdgeInsets.symmetric(vertical: 12);
    
    return Semantics(
      label: semanticLabel,
      button: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientStart, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientStart.withOpacity(highContrast ? 0.7 : 0.5),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(highContrast ? 0.7 : 0.5),
                  width: highContrast ? 2 : 1,
                ),
                left: BorderSide(
                  color: Colors.white.withOpacity(highContrast ? 0.5 : 0.3),
                  width: highContrast ? 2 : 1,
                ),
              ),
            ),
            child: Padding(
              padding: contentPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(highContrast ? 0.5 : 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.star,
                          color: textColor,
                          size: iconSize,
                        ),
                      ),
                      SizedBox(width: largeText ? 16 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Premium Coordination',
                              style: TextStyle(
                                color: textColor,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: largeText ? 6 : 4),
                            Text(
                              'Guaranteed seat for waitlisted passengers',
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: subtitleSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: largeText ? 20 : 16),
                  Row(
                    children: [
                      _buildAccessiblePremiumFeature(context, Icons.verified_user, 'Verified Buddies'),
                      _buildAccessiblePremiumFeature(context, Icons.support_agent, 'Priority Support'),
                      _buildAccessiblePremiumFeature(context, Icons.speed, 'Fast Matching'),
                    ],
                  ),
                  SizedBox(height: largeText ? 20 : 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Premium features coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: buttonTextColor,
                        padding: buttonPadding,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: highContrast ? const BorderSide(color: Colors.white, width: 2) : BorderSide.none,
                        ),
                        elevation: highContrast ? 4 : 0,
                      ),
                      child: Text(
                        'Upgrade Now',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: buttonTextSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAccessiblePremiumFeature(BuildContext context, IconData icon, String label) {
    // Adjust for accessibility
    final highContrast = AccessibilityUtils.hasHighContrast(context);
    final largeText = AccessibilityUtils.hasLargeText(context);
    
    // Adjust text size for large text mode
    final labelSize = AccessibilityUtils.getScaledFontSize(context, 12);
    final iconSize = AccessibilityUtils.getScaledIconSize(context, 24);
    
    return Expanded(
      child: Semantics(
        label: label,
        child: Column(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: iconSize,
              semanticLabel: null, // Let the parent Semantics handle this
            ),
            SizedBox(height: largeText ? 10 : 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: labelSize,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  
  /// Build skeleton UI for loading state
  List<Widget> _buildSkeletonUI() {
    return [
      // Skeleton welcome header
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: const SkeletonCard(
            height: 120,
            hasHeader: true,
            hasFooter: false,
          ),
        ),
      ),
      
      // Skeleton section title
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: SkeletonLoader(height: 24, width: 120),
        ),
      ),
      
      // Skeleton core services grid
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildListDelegate([
            const SkeletonGridItem(),
            const SkeletonGridItem(),
            const SkeletonGridItem(),
            const SkeletonGridItem(),
          ]),
        ),
      ),
      
      // Skeleton train services section title
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
          child: SkeletonLoader(height: 24, width: 150),
        ),
      ),
      
      // Skeleton train services horizontal list
      SliverToBoxAdapter(
        child: SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) {
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 16),
                child: const SkeletonGridItem(
                  height: 160,
                  width: 160,
                ),
              );
            },
          ),
        ),
      ),
      
      // Skeleton premium features section title
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
          child: SkeletonLoader(height: 24, width: 180),
        ),
      ),
      
      // Skeleton premium feature card
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const SkeletonCard(
            height: 180,
            hasHeader: true,
            hasFooter: true,
          ),
        ),
      ),
      
      // Bottom padding
      const SliverToBoxAdapter(
        child: SizedBox(height: 40),
      ),
    ];
  }
}

class BackgroundPainter extends CustomPainter {
  final double animation;
  final double scrollOffset;
  final bool useSimpleAnimations;
  final bool lowPowerMode;

  BackgroundPainter({
    required this.animation, 
    required this.scrollOffset,
    this.useSimpleAnimations = false,
    this.lowPowerMode = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Background gradient - always draw this regardless of performance settings
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      colors: const [
        Color(0xFF1A237E),
        Color(0xFF303F9F),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
    
    paint.shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    
    // Skip additional effects in low power mode
    if (lowPowerMode) {
      return;
    }
    
    // Draw animated circles - fewer for simple animations
    final circleCount = useSimpleAnimations ? 3 : 5;
    for (int i = 0; i < circleCount; i++) {
      final progress = (animation + i / circleCount) % 1.0;
      final circleSize = 100.0 + 50.0 * i;
      
      // Simpler calculation for low-end devices
      final x = useSimpleAnimations
          ? size.width * (0.2 + 0.6 * i / circleCount)
          : size.width * (0.2 + 0.6 * i / circleCount) + math.sin(animation * math.pi * 2 + i) * 30;
          
      final y = -circleSize / 2 + progress * (size.height + circleSize) - 
                (useSimpleAnimations ? 0 : scrollOffset * 0.3);
      
      final circlePaint = Paint()
        ..color = Colors.white.withOpacity(0.03 + 0.02 * i)
        ..style = PaintingStyle.fill;
        
      canvas.drawCircle(Offset(x, y), circleSize, circlePaint);
    }
    
    // Draw animated lines - fewer and simpler for low-end devices
    final lineCount = useSimpleAnimations ? 1 : 3;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    for (int i = 0; i < lineCount; i++) {
      final path = Path();
      final startX = -size.width * 0.2;
      final endX = size.width * 1.2;
      final waveHeight = 100.0 + i * 50.0;
      final frequency = 0.01 - 0.002 * i;
      final speed = animation * math.pi * 2 * (1 + i * 0.5);
      final yOffset = size.height * (0.3 + 0.2 * i) - 
                     (useSimpleAnimations ? 0 : scrollOffset * 0.2);
      
      path.moveTo(startX, yOffset);
      
      // Use larger step size for simple animations to reduce drawing operations
      final step = useSimpleAnimations ? 15.0 : 5.0;
      for (double x = startX; x <= endX; x += step) {
        final y = yOffset + math.sin(x * frequency + speed) * waveHeight;
        path.lineTo(x, y);
      }
      
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation || oldDelegate.scrollOffset != scrollOffset;
  }
}
