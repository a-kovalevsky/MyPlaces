//
//  MapViewController.swift
//  Pods
//
//  Created by andrew on 30.05.22.
//

import UIKit
import MapKit
import CoreLocation //для управления всеми действиями связанными с местоположением пользователя

protocol MapViewControllerDelegate {
    func getAddress(_ address: String?)
}

class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()//этот объект будет управлять геопозицией и остальной шнягой
    let radius = 1000.0
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?
    var directionArray: [MKDirections] = []//массив чтоб маршруты не накладывались друг на друга
    var previousLocation: CLLocation? {
        didSet {
            startTrackingUserLocation()
        }
    } //для передвижения карты необходимо знать прошлое значение локации
    
    @IBOutlet weak var mapPinImage: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var goButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self//можно назначить делегат мэпвью через селф,указав что им является этот селф класс,либо в интерфейс билдере стрелочкой от элемента с контрл и на сам вью контроллер
        setupMapView()
        checkLocationServices()
    }
    
    @IBAction func closeVC() {
        dismiss(animated: true)
    }
    @IBAction func centerViewInUserLocation() {
//        if let location = locationManager.location?.coordinate {
//            let region = MKCoordinateRegion(center: location, latitudinalMeters: radius,
//                                            longitudinalMeters: radius)
//            mapView.setRegion(region, animated: true)//установка самого региона приблежения при нажатии по координатам локейшн и с радиусом,указанным в свойствах
//        }
        showUserLocation()
    }
    @IBAction func doneButtonPressed(_ sender: Any) {
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        dismiss(animated: true)
    }
    private func setupMapView() {
        
        goButton.isHidden = true
        
        if incomeSegueIdentifier == "ShowPlace" {
            setupPlacemark()
            mapPinImage.isHidden = true
            addressLabel.isHighlighted = true
            doneButton.isHidden = true
            goButton.isHidden = false
        }
    }
    
    private func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays) //в начале удаляем все маршруты
        directionArray.append(directions)//добавляем принимаемые значения
        let _ = directionArray.map {$0.cancel()}
        directionArray.removeAll() //отменяет все действующие маршруты и удаляет с карты,вызываем перед тем как создать нвоый маршрут
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
    }
    
    private func setupPlacemark() {
        guard let location = place.location else {return}
        
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location){(placemarks,error) in//также может возвращать ошибки и проверяем на них
            if let error = error {
                print(error)
                return
            }
            guard let placemarks = placemarks else {return}//разворачиваем опционал
            
            let placemark = placemarks.first//маркер один всего,метка на карте,описание ниже
            
            let annotation = MKPointAnnotation() // описание точки маркера на карте
            annotation.title = self.place.name
            annotation.subtitle = self.place.type
            
            //привязка аннотации(описания маркера) к конкретной точке на карте
            
            guard let placemarkLocation = placemark?.location else {return}
            annotation.coordinate = placemarkLocation.coordinate
            self.placeCoordinate = placemarkLocation.coordinate
            
            self.mapView.showAnnotations([annotation], animated: true)
            self.mapView.selectAnnotation(annotation, animated: true)
            
        }
    }
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorization()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.newAlert(title: "Your location is not available",
                              message: "To give permission Go to: String -> MyPlaces -> Location")
            }// cоздать алерт контроллер и вызвать его из этого блока есть локейшн сервисы будут фолс(тоесть недоступны)
        }
    }
    private func setupLocationManager() { //установка свойств location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest //тип данных для точности навигации
    }
    
    private func checkLocationAuthorization() {//проверка статуса на разрешение использования геопозиции
        let manager = CLLocationManager()
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if incomeSegueIdentifier == "getAdress"{
                showUserLocation()
            }
            break
        case .denied:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.newAlert(title: "Your location is not available",
                              message: "To give permission Go to: String -> MyPlaces -> Location")
            }
            break
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        case .restricted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.newAlert(title: "Your location is not available",
                              message: "To give permission Go to: String -> MyPlaces -> Location")
            }
            break
        case .authorizedAlways:
            break
        @unknown default://будет срабатывать,если в будущем появится какй-то новый кейс
            print("New case is available")
        }
    }
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: radius,
                                            longitudinalMeters: radius)
            mapView.setRegion(region, animated: true)//установка самого региона приблежения при нажатии по координатам локейшн и с радиусом,указанным в свойствах
        }
    }
    
    private func startTrackingUserLocation() {
        guard let previousLocation = previousLocation else {return}
        let center = getCenterLocation(for: mapView)
        guard center.distance(from: previousLocation) > 50 else {return}//если расстояние от предыдщего метсополоежния  пользователя до текущенго центра составит более 50м то зададим новые координаты предыдшем значения м запускаем showuserlocation
        self.previousLocation = center
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }

    }//условия при которых будет обновлять метсоположение и вызываться show user location
    
    private func getDirections() {
        guard let location = locationManager.location?.coordinate else {newAlert(title: "Error", message: "Current location is not found")//текущее местоположение пользователя
            return
        }
        
        //режим постоянного отслеживавния текущего местоположения после того как текущее местоположение определено
        locationManager.startUpdatingLocation()
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        guard let request = createDirectionsRequest(from: location) else {newAlert(title: "Error", message: "Destination is not found")
            return
        } //построение маршрута
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        //запускаем расчет маршрута
        directions.calculate { (response, error) in //response содержит массив routes  с маршрутами ,классические две проверки для ошибок и ресопнс
            if let error = error {
                print(error)
                return
            }
            guard let response = response else {self.newAlert(title: "Error", message: "Directions is not available")
                return
            }
            for route in response.routes {//route содержит в себеб маршруты MKRoute, но если запрашивать только один вид маршрута будет только один элемент массива
                self.mapView.addOverlay(route.polyline)//накладываем фактически маршрут
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)//будет показывать полностью маршрут
                
                let distance = String(format: "%.1f", route.distance/1000) //формат расстояния округляем до десятых и делим на 1000  И ЭТО ИНФА ВСЯ В routes
                
                let hours = Int(route.expectedTravelTime) / 3600
                let minutes = Int(route.expectedTravelTime) / 60 % 60
                let seconds = Int(route.expectedTravelTime) % 60
                let timeInterval = 	String(format: "%02i:%02i:%02i", hours, minutes, seconds)
               
            }
        }
            
    }
    
    private func createDirectionsRequest (from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        guard let destinationCoordinate = placeCoordinate else {return nil}//берем из координат заведения куда едеб собстна и делаем свойство,это еще но точка так что ниже делаем саму точку,тут только координаты
        let startingLocation = MKPlacemark(coordinate: coordinate)//начальная точка
        let destination = MKPlacemark(coordinate: destinationCoordinate )//конечная точка по координатам ,полученным из placemark
        
        let request = MKDirections.Request()//запрос на построение маршрута имея две точки
        request.source = MKMapItem(placemark: startingLocation)//введение первой точки
        request.destination = MKMapItem(placemark: destination)//конечная точка
        request.transportType = .automobile //тип передвижения
        request.requestsAlternateRoutes = true //дает разрешение на использование нескольких типов маршрута
        
        return request
        
    }//принимает координаты,возвращается настроенный запрос ,который будем юзать но он может и не получится,так что опционал
    
    private func getCenterLocation(for mapView:MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        return CLLocation(latitude: latitude, longitude: longitude)
    }//возвращаем координаты  взятые с мапвью  типом CLLocation
    
    private func newAlert(title:String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alert.addAction(okAction)
        present(alert,animated: true)
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else {return nil}//если маркером является текущее местоположение пользователя (MKUserLocation),то мы не создаем аннотации
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView//чтоб каждый раз не создавать MKAnnotationView при вызове этого метода,советую переиспользовать ранее созданыее аннотации через этот метод
        
       //если annotationView nill,тоесть нет ни одной аннотации которую можно переиспользовать
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true //для отображения ввиде баннера
        }
        if let imageData = place.imageData {//картинку передаем
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        
        return annotationView
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {//при смене региона каждый раз отображается
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()//преобразовывааем координаты в адрес,а до этого в методе плэйсмарк днлали наоборот
        
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUserLocation()
            }
        }
        
        geocoder.cancelGeocode()
        
        geocoder.reverseGeocodeLocation(center){(placemarks,error) in
            if let error = error {
                print(error)
                return
            }
            guard let placemarks = placemarks else {return}//как и тогда,одна метка и две проверки
            
            let placemark = placemarks.first
            let _ = placemark?.thoroughfare
            let _ = placemark?.subThoroughfare
            
//            DispatchQueue.main.async {
//                //проверка на нил так как бывают косяки с местоположением
//                if streetName != nil && buildNumber != nil {
//                    self.addressLabel.text = "\(streetName!),\(buildNumber!)"
//                } else if streetName != nil {
//                    self.addressLabel.text = "\(streetName!)"
//                } else {
//                    self.addressLabel.text = ""
//                }
                
            }
            
        }
    
    //для подсвечиаания маршрута
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)//кастим до полилайна
        renderer.strokeColor = .orange
        return renderer
    }
    
    }

extension MapViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
}
