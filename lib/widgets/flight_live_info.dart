import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/card_model.dart';
import '../services/flight_info_service.dart';

/// Widget to display live flight information
class FlightLiveInfo extends StatefulWidget {
  final CardModel card;

  const FlightLiveInfo({super.key, required this.card});

  @override
  State<FlightLiveInfo> createState() => _FlightLiveInfoState();
}

class _FlightLiveInfoState extends State<FlightLiveInfo> {
  final _flightService = FlightInfoService();
  FlightInfo? _flightInfo;
  WeatherInfo? _weatherInfo;
  bool _isLoading = false;
  bool _hasError = false;
  bool _isExpanded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLiveInfo();
  }

  Future<void> _fetchLiveInfo() async {
    // Check if we have a flight number
    if (widget.card.flightNumber == null || widget.card.flightNumber!.isEmpty) {
      return;
    }

    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _errorMessage = 'Nessuna connessione';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Fetch flight info
      final flightInfo = await _flightService.getFlightInfo(
        widget.card.flightNumber!,
        widget.card.flightDate,
      );

      // Fetch weather at destination if we have arrival airport
      WeatherInfo? weatherInfo;
      if (flightInfo?.arrivalAirport != null) {
        weatherInfo = await _flightService.getWeatherAtAirport(
          flightInfo!.arrivalAirport!,
        );
      }

      if (mounted) {
        setState(() {
          _flightInfo = flightInfo;
          _weatherInfo = weatherInfo;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
          _errorMessage = 'Impossibile caricare info';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Don't show if no flight number
    if (widget.card.flightNumber == null || widget.card.flightNumber!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withValues(alpha: 0.15),
            Colors.blue.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Live indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isLoading 
                          ? Colors.orange 
                          : (_flightInfo != null ? Colors.green : Colors.grey),
                      boxShadow: _flightInfo != null ? [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ] : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Info Live',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (_isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.blue),
                      ),
                    )
                  else if (_flightInfo != null) ...[
                    Text(
                      '${_flightInfo!.statusEmoji} ${_flightInfo!.statusDisplay}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (_isExpanded)
            _buildExpandedContent(),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasError || _errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, 
                color: Colors.white.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 8),
            Text(
              _errorMessage ?? 'Servizio non disponibile',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _fetchLiveInfo,
              child: const Text('Riprova', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      );
    }

    if (_flightInfo == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.flight_outlined, 
                color: Colors.white.withValues(alpha: 0.5), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Configura le API keys per info in tempo reale',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          
          // Gate info
          if (_flightInfo!.departureGate != null)
            _buildInfoRow(
              '🚪',
              'Gate',
              _flightInfo!.departureGate!,
              highlight: true,
            ),
          
          // Terminal
          if (_flightInfo!.departureTerminal != null)
            _buildInfoRow(
              '🏢',
              'Terminal',
              _flightInfo!.departureTerminal!,
            ),
          
          // Delay warning
          if (_flightInfo!.hasDelay)
            _buildInfoRow(
              '⚠️',
              'Ritardo',
              '+${_flightInfo!.delayMinutes} min',
              isWarning: true,
            ),
          
          // Estimated departure
          if (_flightInfo!.estimatedDeparture != null)
            _buildInfoRow(
              '🕐',
              'Partenza stimata',
              _formatTime(_flightInfo!.estimatedDeparture!),
            ),
          
          // Weather at destination
          if (_weatherInfo != null) ...[
            const SizedBox(height: 8),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            _buildWeatherRow(),
          ],
          
          // Refresh button
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _fetchLiveInfo,
                icon: Icon(Icons.refresh, size: 16, 
                    color: Colors.white.withValues(alpha: 0.6)),
                label: Text(
                  'Aggiorna',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String label, String value, 
      {bool highlight = false, bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const Spacer(),
          Container(
            padding: highlight || isWarning
                ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                : null,
            decoration: highlight || isWarning
                ? BoxDecoration(
                    color: isWarning 
                        ? Colors.orange.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Text(
              value,
              style: TextStyle(
                color: isWarning 
                    ? Colors.orange 
                    : (highlight ? Colors.green : Colors.white),
                fontSize: 14,
                fontWeight: highlight || isWarning 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow() {
    return Row(
      children: [
        Text(_weatherInfo!.weatherEmoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meteo a destinazione',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_weatherInfo!.temperature?.round()}°C • ${_weatherInfo!.description ?? ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
