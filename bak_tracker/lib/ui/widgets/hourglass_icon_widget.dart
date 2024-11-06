// HourglassIcon Widget
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HourglassIcon extends StatefulWidget {
  final Duration duration;

  const HourglassIcon({super.key, required this.duration});

  @override
  _HourglassIconState createState() => _HourglassIconState();
}

class _HourglassIconState extends State<HourglassIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  IconData _hourglassIcon = FontAwesomeIcons.hourglassStart;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _controller.addListener(_updateHourglassIcon);
  }

  void _updateHourglassIcon() {
    final progress = _controller.value;
    setState(() {
      if (progress < 0.33) {
        _hourglassIcon = FontAwesomeIcons.hourglassStart;
      } else if (progress < 0.66) {
        _hourglassIcon = FontAwesomeIcons.hourglassHalf;
      } else {
        _hourglassIcon = FontAwesomeIcons.hourglassEnd;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Icon(
      _hourglassIcon,
      color: Colors.orangeAccent,
      size: 28,
    );
  }
}
