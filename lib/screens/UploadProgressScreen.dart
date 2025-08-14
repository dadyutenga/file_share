import 'dart:async';
import 'package:flutter/material.dart';

class UploadProgressScreen extends StatefulWidget {
  final String fileName;
  const UploadProgressScreen({Key? key, this.fileName = 'file.txt'}) : super(key: key);

  @override
  _UploadProgressScreenState createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  double _progress = 0.0;
  bool _isPaused = false;
  bool _isCanceled = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      if (_isPaused || _isCanceled) return;
      if (_progress >= 1.0) {
        t.cancel();
        setState(() {}); // refresh to show completed state
        return;
      }
      setState(() {
        _progress = (_progress + 0.02).clamp(0.0, 1.0);
      });
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _cancelUpload() {
    _timer?.cancel();
    setState(() {
      _isCanceled = true;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildControls() {
    if (_isCanceled) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('Close'),
      );
    }

    if (_progress >= 1.0) {
      return ElevatedButton(
        onPressed: () => Navigator.of(context).maybePop(),
        child: const Text('Done'),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _togglePause,
          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
          label: Text(_isPaused ? 'Resume' : 'Pause'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _cancelUpload,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          icon: const Icon(Icons.cancel),
          label: const Text('Cancel'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toStringAsFixed(0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Progress'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isCanceled)
                const Icon(Icons.cancel, color: Colors.redAccent, size: 72)
              else if (_progress >= 1.0)
                const Icon(Icons.check_circle, color: Colors.green, size: 72)
              else
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: _progress, strokeWidth: 8),
                      Text('${percent}%'),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              Text(widget.fileName, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              SizedBox(
                height: 6,
                child: LinearProgressIndicator(value: _progress),
              ),
              const SizedBox(height: 20),
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }
}