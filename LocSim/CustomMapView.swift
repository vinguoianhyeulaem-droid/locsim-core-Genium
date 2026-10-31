//
//  CustomMapView.swift
//  Geranium
//
//  Created by cclerc on 21.12.23.
//

import SwiftUI
import MapKit

struct CustomMapView: UIViewRepresentable {
    @Binding var tappedCoordinate: EquatableCoordinate?
    @Binding var targetCoordinate: EquatableCoordinate?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true

        let tapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapRecognizer)

        // Nhấn giữ để chọn vị trí; không cho tap nhận cùng một lần nhấn giữ.
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleLongPress(_:))
        )
        longPressRecognizer.minimumPressDuration = 0.45
        tapRecognizer.require(toFail: longPressRecognizer)
        mapView.addGestureRecognizer(longPressRecognizer)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        context.coordinator.parent = self
        guard let target = targetCoordinate?.coordinate else { return }
        if let previous = context.coordinator.previousTarget,
           previous.latitude == target.latitude && previous.longitude == target.longitude { return }
        let isFirstTarget = context.coordinator.previousTarget == nil
        context.coordinator.previousTarget = target
        // Only initialize zoom on the first target. For all subsequent targets,
        // recenter WITHOUT changing the user's current zoom level.
        // Calling setRegion with a hardcoded span on every selection caused zoom-out.
        if isFirstTarget {
            uiView.setRegion(MKCoordinateRegion(center: target,
                              span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)), animated: false)
        } else {
            // A point picked on the map is already within the visible region;
            // do not move the camera. For typed coordinates, move its center only.
            uiView.setCenter(target, animated: true)
        }
        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })
        let pin = MKPointAnnotation()
        pin.coordinate = target
        uiView.addAnnotation(pin)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        var previousTarget: CLLocationCoordinate2D?

        init(_ parent: CustomMapView) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended, let mapView = gesture.view as? MKMapView else { return }
            selectCoordinate(at: gesture.location(in: mapView), on: mapView)
        }

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began, let mapView = gesture.view as? MKMapView else { return }
            selectCoordinate(at: gesture.location(in: mapView), on: mapView)
        }

        private func selectCoordinate(at point: CGPoint, on mapView: MKMapView) {
            let selected = mapView.convert(point, toCoordinateFrom: mapView)
            // Manual map selection only updates the marker and tappedCoordinate.
            // Leave previousTarget untouched: it tracks typed-coordinate camera moves.
            // LocSimView does not set targetCoordinate for manual selections.
            // Đặt ghim ngay khi chạm, không phụ thuộc vào lệnh mô phỏng GPS.
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            let pin = MKPointAnnotation()
            pin.coordinate = selected
            mapView.addAnnotation(pin)
            parent.tappedCoordinate = EquatableCoordinate(coordinate: selected)
        }
    }
}
