import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:collection/collection.dart';
import 'dart:ui' as ui;

class ClusterManager {
  static const double CLUSTER_ZOOM_THRESHOLD = 10.0; // この値より縮小表示時にクラスター化
  static const double CLUSTER_DISTANCE = 50.0; // クラスター化する距離（ピクセル単位）

  final GoogleMapController mapController;
  final List<MarkerData> markers;
  
  ClusterManager({
    required this.mapController,
    required this.markers,
  });

  Future<Set<Marker>> getClusteredMarkers(double zoom) async {
    if (zoom >= CLUSTER_ZOOM_THRESHOLD) {
      // ズームレベルが閾値以上の場合は通常のマーカーを表示
      return markers.map((data) => data.toMarker()).toSet();
    }

    // スクリーン座標での位置を計算
    final clusters = <MarkerCluster>[];
    for (var marker in markers) {
      ScreenCoordinate screenCoordinate = await mapController.getScreenCoordinate(
        LatLng(marker.position.latitude, marker.position.longitude),
      );
      
      // 既存のクラスターを探す
      var cluster = clusters.firstWhereOrNull(
        (c) => _isWithinClusterDistance(c.centerScreen, screenCoordinate),
      );

      if (cluster != null) {
        cluster.addMarker(marker, screenCoordinate);
      } else {
        clusters.add(MarkerCluster(marker, screenCoordinate, mapController));
      }
    }

    // クラスターをマーカーに変換
    final Set<Marker> clusterMarkers = {};
    for (var cluster in clusters) {
      clusterMarkers.add(await cluster.toMarker());
    }
    return clusterMarkers;
  }

  bool _isWithinClusterDistance(ScreenCoordinate a, ScreenCoordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy) <= (CLUSTER_DISTANCE * CLUSTER_DISTANCE);
  }
}

class MarkerData {
  final String id;
  final LatLng position;
  final String title;
  final String snippet;
  final bool isVisited;
  final Function() onTap;

  MarkerData({
    required this.id,
    required this.position,
    required this.title,
    required this.snippet,
    required this.isVisited,
    required this.onTap,
  });

  Marker toMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      onTap: onTap,
      icon: isVisited
          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
          : BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
    );
  }
}

class MarkerCluster {
  final List<MarkerData> markers = [];
  final GoogleMapController mapController;
  ScreenCoordinate centerScreen;
  LatLng? center;

  MarkerCluster(MarkerData initial, this.centerScreen, this.mapController) {
    addMarker(initial, centerScreen);
  }

  void addMarker(MarkerData marker, ScreenCoordinate position) {
    markers.add(marker);
    _updateCenter();
  }

  void _updateCenter() {
    double lat = 0;
    double lng = 0;
    for (var marker in markers) {
      lat += marker.position.latitude;
      lng += marker.position.longitude;
    }
    center = LatLng(lat / markers.length, lng / markers.length);
  }

  Future<BitmapDescriptor> _createClusterBitmap() async {
    const double size = 120;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final Paint circlePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // 背景の白い円を描画
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      Paint()..color = Colors.white,
    );

    // 赤い円を描画
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      (size / 2) - 2, // 白い縁取りのために少し小さく
      circlePaint,
    );

    // テキストを描画
    final textPainter = TextPainter(
      text: TextSpan(
        text: markers.length.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  Future<Marker> toMarker() async {
    final icon = await _createClusterBitmap();
    
    return Marker(
      markerId: MarkerId('cluster_${center!.latitude}_${center!.longitude}'),
      position: center!,
      icon: icon,
      anchor: const Offset(0.5, 0.5),
      onTap: () {
        mapController.animateCamera(
          CameraUpdate.newLatLngZoom(center!, ClusterManager.CLUSTER_ZOOM_THRESHOLD),
        );
      },
    );
  }
}