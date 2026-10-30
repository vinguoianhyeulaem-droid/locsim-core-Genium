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
        mapView.layer.cornerRadius = 15
        mapView.layer.masksToBounds = true

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
        context.coordinator.previousTarget = target
        uiView.setRegion(MKCoordinateRegion(center: target,
                          span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)), animated: true)
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
            // Mark this selection as already handled before the SwiftUI binding update.
            // updateUIView must NOT call setRegion for a point picked on the map,
            // otherwise the zoom snaps back to the fixed default span.
            previousTarget = selected
            // Đặt ghim ngay khi chạm, không phụ thuộc vào lệnh mô phỏng GPS.
            mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
            let pin = MKPointAnnotation()
            pin.coordinate = selected
            mapView.addAnnotation(pin)
            parent.tappedCoordinate = EquatableCoordinate(coordinate: selected)
        }
    }
}
